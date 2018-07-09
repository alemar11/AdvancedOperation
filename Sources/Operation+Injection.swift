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

public struct InjectionRequirements: OptionSet { //TODO: rename in InjectionRequirements?
  public let rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// The injected input is required.
  public static let validInput = InjectionRequirements(rawValue: 1)
  /// The first operation must finish without errors.
  public static let successful = InjectionRequirements(rawValue: 2)
  ///  The first operation must finish without being cancelled.
  public static let noCancellation = InjectionRequirements(rawValue: 3)
}

extension OperationOutputType where Self: AdvancedOperation {
  /// Creates a new operation that passes the output of `self` into the given `AdvancedOperation`
  ///
  /// - Parameter operation: The operation that needs the output of `self` to generate an output.
  /// - Returns: Returns an *adapter* operation which passes the output of `self` into the given `AdvancedOperation`
  func inject<E: OperationInputType & AdvancedOperation>(into operation: E, requirements: InjectionRequirements = []) -> AdvancedBlockOperation where Output == E.Input {
    return AdvancedOperation.injectOperation(self, into: operation)
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
  class func injectOperation<F: OperationOutputType & AdvancedOperation, G: OperationInputType & AdvancedOperation>(_ outputOperation: F, into inputOpertion: G, requirements: InjectionRequirements = []) -> AdvancedBlockOperation where F.Output == G.Input {
    let adapterOperation = AdvancedBlockOperation { [unowned outputOperation = outputOperation, unowned inputOpertion = inputOpertion] complete in

      let error: NSError? = {
        if requirements.contains(.validInput) && outputOperation.output != nil {
          return NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
        }

        if requirements.contains(.successful), !outputOperation.errors.isEmpty {
          return NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
        }

        if requirements.contains(.noCancellation), outputOperation.isCancelled {
          return NSError(domain: "\(identifier).Adapter", code: OperationErrorCode.conditionFailed.rawValue, userInfo: nil) //TODO better errors
        }

        return nil
      }()

      inputOpertion.input = outputOperation.output
      if let error = error {
        inputOpertion.cancel(error: error)
      }
      complete([])
    }

    adapterOperation.addDependency(outputOperation)
    inputOpertion.addDependency(adapterOperation)

    return adapterOperation

  }
}
