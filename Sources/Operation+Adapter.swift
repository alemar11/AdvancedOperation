//
// AdvancedOperation
//
// Copyright © 2016-2018 Tinrobots.
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

// MARK: - Function

public protocol OperationInputType: AnyObject {
  associatedtype Input
  var input: Input? { get set }
}

public protocol OperationOutputType: AnyObject {
  associatedtype Output
   var output: Output? { get set }
}

public typealias OperationWithInput = AdvancedOperation & OperationInputType
public typealias OperationWithOutput = AdvancedOperation & OperationOutputType
public typealias OperationWithInputAndOuput = OperationWithInput & OperationWithOutput

public struct AdapterRequirements: OptionSet { //TODO: rename in InjectionRequirements?
  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// The injected input is required.
  public static let validInput = AdapterRequirements(rawValue: 1)
  /// The first operation must finish without errors.
  public static let successful = AdapterRequirements(rawValue: 2)
  ///  The first operation must finish without being cancelled.
  public static let noCancellation = AdapterRequirements(rawValue: 3)
}

/// An `AdvancedOperation` with input and output values.
public class FunctionOperation<I, O> : AdvancedOperation, OperationInputType & OperationOutputType { //TODO: remove?
  /// A generic input.
  public var input: I?

  /// A generic output.
  public var output: O?
}

extension OperationOutputType where Self: AdvancedOperation {
  /// Creates a new operation that passes the output of `self` into the given `AdvancedOperation`
  ///
  /// - Parameter operation: The operation that needs the output of `self` to generate an output.
  /// - Returns: Returns an *adapter* operation which passes the output of `self` into the given `AdvancedOperation`
  func adapt<E: OperationInputType & AdvancedOperation>(into operation: E, requirements: AdapterRequirements = []) -> AdvancedBlockOperation where Output == E.Input {
    return AdvancedOperation.adaptOperations((self, operation), requirements: requirements)
  }
}

// MARK: - Adapter

public extension AdvancedOperation {

  /// Creates an *adapter* operation which passes the output from the first `AdvancedOperation` into the input of the second `AdvancedOperation`
  ///
  /// - Parameter operations: a tuple of Operations where the second one needs, as input, the output of the first one.
  /// - Returns: Returns an *adapter* operation which passes the output from the first `AdvancedOperation` into the input of the second `AdvancedOperation`,
  /// and builds dependencies so the first operation runs first, then the adapter, then second operation.
  /// - Note: The client is still responsible for adding all three blocks to a queue.
  // swiftlint:disable:next line_length
  class func adaptOperations<F: OperationOutputType & AdvancedOperation, G: OperationInputType & AdvancedOperation>(_ operations: (F, G), requirements: AdapterRequirements = []) -> AdvancedBlockOperation where F.Output == G.Input {
    let adapterOperation = AdvancedBlockOperation { [unowned operation0 = operations.0, unowned operation1 = operations.1] complete in
      // requirements validation
      //TODO: validate only one error, and if the operation is cancelled, move on
      if requirements.contains(.noCancellation), operation0.isCancelled {
        let error = NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
        operation1.cancel(error: error)
      }

      if requirements.contains(.successful), !operation0.errors.isEmpty {
        let error = NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
        operation1.cancel(error: error)
      }

      if requirements.contains(.validInput) && operation0.output != nil {
        let error = NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
         operation1.cancel(error: error)
      }

      operation1.input = operation0.output
      complete([])
    }

    adapterOperation.addDependency(operations.0)
    operations.1.addDependency(adapterOperation)

    return adapterOperation
  }
}
