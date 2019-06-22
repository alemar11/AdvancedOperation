//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

// AdvancedOperation conforming to this protocol, requires an input to be executed.
public protocol InputRequiring: AdvancedOperation {
  associatedtype Input
  var input: Input? { get set }
}

// AdvancedOperation conforming to this protocol, produce an output once finished.
public protocol OutputProducing: AdvancedOperation {
  associatedtype Output
  var output: Output? { get set }
}

@available(*, deprecated, message: "Use InputRequiring instead.")
public typealias OperationInputHaving = InputRequiring

@available(*, deprecated, message: "Use OutputProducing instead.")
public typealias OperationOutputHaving = OutputProducing

/// An `OptionSet` containing a list of option that an injected input should have.
public struct InjectedInputRequirements: OptionSet {
  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// The injected input is required.
  public static let notOptional = InjectedInputRequirements(rawValue: 1)
  /// The injected input is a result of a successul operation
  public static let successful = InjectedInputRequirements(rawValue: 2)
  /// The injected input is a result of a not cancelled operation
  public static let noCancellation = InjectedInputRequirements(rawValue: 4)
}

extension OutputProducing where Self: AdvancedOperation {
  /// Creates a new operation that passes the output of `self` into the given `AdvancedOperation`
  ///
  /// - Parameters:
  ///   - operation: The operation that needs the output of `self` to generate an output.
  ///   - requirements: A list of options that the injected input must satisfy.
  /// - Returns: Returns an *adapter* operation which passes the output of `self` into the given `AdvancedOperation`.
  public func inject<E: InputRequiring>(into operation: E,
                                        requirements: InjectedInputRequirements = [.notOptional, .successful]) -> AdvancedBlockOperation where Output == E.Input {
    return AdvancedOperation.injectOperation(self, into: operation, requirements: requirements)
  }

  /// Creates a new operation that passes, once transformed, the output of `self` into the given `AdvancedOperation`.
  ///
  /// - Parameters:
  ///   - operation: The operation that needs the transformed output of `self` to generate an output.
  ///   - requirements: A list of options that the injected input must satisfy.
  ///   - transform: Closure to transform the output of `self` into a valid `input` for the next operation.
  /// - Returns: Returns an *adapter* operation which passes the transformed output of `self` into the given `AdvancedOperation`.
  public func inject<E: InputRequiring>(into operation: E,
                                        requirements: InjectedInputRequirements = [.notOptional, .successful],
                                        transform: @escaping (Output?) -> E.Input?) -> AdvancedBlockOperation {
    return AdvancedOperation.injectOperation(self, into: operation, requirements: requirements, transform: { transform($0) })
  }
}

// MARK: - Adapter

extension AdvancedOperation {
  /// Creates an *adapter* operation which passes the output from the `outputOperation` into the input of the `inputOpertion`.
  ///
  /// - Parameters:
  ///   - outputOperation: The operation whose output is needed by the `inputOperation`.
  ///   - inputOpertion: The operation who needs needs, as input, the output of the `inputOperation`.
  ///   - requirements: A set of `InjectedInputRequirements`.
  /// - Returns: Returns an *adapter* operation which passes the output from the `outputOperation` into the input of the `inputOpertion`,
  /// and builds dependencies so the outputOperation runs first, then the adapter, then inputOpertion.
  /// - Note: The client is still responsible for adding all three blocks to a queue.
  class func injectOperation<F: OutputProducing, G: InputRequiring>(_ outputOperation: F,
                                                                    into inputOpertion: G,
                                                                    requirements: InjectedInputRequirements = []) -> AdvancedBlockOperation where F.Output == G.Input {
    let adapterOperation = AdvancedBlockOperation { [unowned outputOperation = outputOperation, unowned inputOpertion = inputOpertion] complete in

      let error = AdvancedOperation.evaluateOutputOperation(outputOperation, forRequirements: requirements)

      if let error = error {
        inputOpertion.cancel(errors: [error])
      } else {
        inputOpertion.input = outputOperation.output
      }

      complete([])
    }

    adapterOperation.addDependency(outputOperation)
    inputOpertion.addDependency(adapterOperation)

    return adapterOperation
  }

  /// Creates an *adapter* operation which passes, once transformed, the output from the `outputOperation` into the input of the `inputOpertion`.
  ///
  /// - Parameters:
  ///   - outputOperation: The operation whose output is needed by the `inputOperation`.
  ///   - inputOpertion: The operation who needs needs, as input, the output of the `inputOperation`.
  ///   - requirements: A set of `InjectedInputRequirements`.
  ///   - transform: Closure to transform the output of `self` into a valid `input` for the next operation.
  /// - Returns: Returns an *adapter* operation which passes the transformed output from the `outputOperation` into the input of the `inputOpertion`,
  /// and builds dependencies so the outputOperation runs first, then the adapter, then inputOpertion.
  /// - Note: The client is still responsible for adding all three blocks to a queue.
  class func injectOperation<F: OutputProducing, G: InputRequiring>(_ outputOperation: F,
                                                                    into inputOpertion: G,
                                                                    requirements: InjectedInputRequirements = [],
                                                                    transform: @escaping (F.Output?) -> G.Input?) -> AdvancedBlockOperation {
    let adapterOperation = AdvancedBlockOperation { [unowned outputOperation = outputOperation, unowned inputOpertion = inputOpertion] complete in

      let error = AdvancedOperation.evaluateOutputOperation(outputOperation, forRequirements: requirements)

      if let error = error {
        inputOpertion.cancel(errors: [error])
      } else {
        inputOpertion.input = transform(outputOperation.output)
      }

      complete([])
    }

    adapterOperation.addDependency(outputOperation)
    inputOpertion.addDependency(adapterOperation)

    return adapterOperation
  }

  private class func evaluateOutputOperation<F: OutputProducing>(_ outputOperation: F, forRequirements requirements: InjectedInputRequirements) -> NSError? {
    if requirements.contains(.notOptional) && outputOperation.output == nil {
      return AdvancedOperationError.executionCancelled(message: "The injectable input is nil and it doesn't satisfy the requirements (\(requirements).")
    }

    if requirements.contains(.successful), !outputOperation.errors.isEmpty {
      return AdvancedOperationError.executionCancelled(message: "The injectable operation contains errors and it doesn't satisfy the requirements (\(requirements).")
    }

    if requirements.contains(.noCancellation), outputOperation.isCancelled {
      return AdvancedOperationError.executionCancelled(message: "The injectable operation is cancelled and it doesn't satisfy the requirements (\(requirements).")
    }

    return nil
  }
}
