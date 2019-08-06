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

extension OutputProducing {
  @discardableResult
  public func injectOutput<E: InputRequiring>(into operation: E) -> Self where Output == E.Input {
    return injectOutput(into: operation, transform: { (output) -> E.Input? in return output })
  }

  @discardableResult
  public func injectOutput<E: InputRequiring>(into operation: E, transform: @escaping (Output?) -> E.Input?) -> Self {
    precondition(operation !== self, "Cannot inject output of self into self.")
    precondition(state == .pending, "Injection cannot be done after the OutputProducing operation execution has begun.")
    precondition(operation.state == .pending, "Injection cannot be done after the InputRequiring oepration execution has begun.")

    let willFinishObserver = WillFinishObserver { [unowned self, unowned operation] _, error in
      if let error = error {
        // TODO: error from injected operation
        operation.cancel(error: error)
      } else {
        // TODO error from injected operation
        operation.input = transform(self.output)
      }

    }

    let didCanceObserver = DidCancelObserver { [unowned operation] _, error in
      // TODO: error from injected operation
      operation.cancel(error: error)
    }

    self.addObserver(didCanceObserver)
    self.addObserver(willFinishObserver)

    // TODO what about conditions? It shouldn't cause any problems but test it
    // TODO test any leaks

    operation.addDependency(self)

    return self
  }
}

//extension OutputProducing {
//  /// Creates a new operation that passes the output of `self` into the given `AdvancedOperation`
//  ///
//  /// - Parameters:
//  ///   - operation: The operation that needs the output of `self` to generate an output.
//  /// - Returns: Returns an *adapter* operation which passes the output of `self` into the given `AdvancedOperation`.
//  public func injectOutput<E: InputRequiring>(into operation: E) -> AdvancedOperation where Output == E.Input {
//    return AdvancedOperation.injectOperation(self, into: operation)
//  }
//
//  /// Creates a new operation that passes, once transformed, the output of `self` into the given `AdvancedOperation`.
//  ///
//  /// - Parameters:
//  ///   - operation: The operation that needs the transformed output of `self` to generate an output.
//  ///   - transform: Closure to transform the output of `self` into a valid `input` for the next operation.
//  /// - Returns: Returns an *adapter* operation which passes the transformed output of `self` into the given `AdvancedOperation`.
//  public func injectOutput<E: InputRequiring>(into operation: E, transform: @escaping (Output?) -> E.Input?) -> AdvancedOperation {
//    return AdvancedOperation.injectOperation(self, into: operation, transform: { transform($0) })
//  }
//}
//
//// MARK: - Adapter
//
//extension AdvancedOperation {
//  /// Creates an *adapter* operation which passes the output from the `outputProducingOperation` into the input of the `inputRequiringOperation`.
//  ///
//  /// - Parameters:
//  ///   - outputProducingOperation: The operation whose output is needed by the `inputRequiringOperation`.
//  ///   - requirements: A set of `InjectedInputRequirements`.
//  /// - Returns: Returns an *adapter* operation which passes the output from the `outputProducingOperation` into the input of the `inputRequiringOperation`,
//  /// and builds dependencies so the outputProducingOperation runs first, then the adapter, then inputRequiringOperation.
//  /// - Note: The client is still responsible for adding all three blocks to a queue.
//  /// - Warning: When adding the three operations to a queue, instead of adding every operation separately with Operation.addOperation(_:), prefer using `addOperations(_:waitUntilFinished:)`.
//  class func injectOperation<F: OutputProducing, G: InputRequiring>(_ outputProducingOperation: F,
//                                                                    into inputRequiringOperation: G) -> AdvancedOperation where F.Output == G.Input {
//    precondition(!outputProducingOperation.isFinished, "The output producing Operation is already finished.")
//    precondition(!inputRequiringOperation.isFinished, "The input requiring Operation is already finished.")
//
//    let adapterOperation = AdvancedBlockOperation { [unowned outputProducingOperation = outputProducingOperation, unowned inputRequiringOperation = inputRequiringOperation] complete in
//      inputRequiringOperation.input = outputProducingOperation.output
//      complete(nil)
//    }
//
//    adapterOperation.addDependency(outputProducingOperation)
//    inputRequiringOperation.addDependency(adapterOperation)
//
//    return adapterOperation
//  }
//
//  /// Creates an *adapter* operation which passes, once transformed, the output from the `outputProducingOperation` into the input of the `inputRequiringOperation`.
//  ///
//  /// The injection takes places only if both operations aren't cancelled or finished.
//  ///
//  /// - Parameters:
//  ///   - outputProducingOperation: The operation whose output is needed by the `inputRequiringOperation`.
//  ///   - inputRequiringOperation: The operation who needs needs, as input, the output of the `inputRequiringOperation`.
//  ///   - transform: Closure to transform the output of `self` into a valid `input` for the next operation.
//  /// - Returns: Returns an *adapter* operation which passes the transformed output from the `outputProducingOperation` into the input of the `inputRequiringOperation`,
//  /// and builds dependencies so the outputProducingOperation runs first, then the adapter, then inputRequiringOperation.
//  /// - Note: The client is still responsible for adding all three blocks to a queue.
//  /// - Warning: When adding the three operations to a queue, instead of adding every operation separately with Operation.addOperation(_:), prefer using `addOperations(_:waitUntilFinished:)`.
//  class func injectOperation<F: OutputProducing, G: InputRequiring>(_ outputProducingOperation: F,
//                                                                    into inputRequiringOperation: G,
//                                                                    transform: @escaping (F.Output?) -> G.Input?) -> AdvancedOperation {
//    precondition(!outputProducingOperation.isFinished, "The output producing Operation is already finished.")
//    precondition(!inputRequiringOperation.isFinished, "The input requiring Operation is already finished.")
//
//    let adapterOperation = AdvancedBlockOperation { [unowned outputProducingOperation = outputProducingOperation, unowned inputRequiringOperation = inputRequiringOperation] complete in
//      inputRequiringOperation.input = transform(outputProducingOperation.output)
//      complete(nil)
//    }
//
//    adapterOperation.addDependency(outputProducingOperation)
//    inputRequiringOperation.addDependency(adapterOperation)
//
//    return adapterOperation
//  }
//}
