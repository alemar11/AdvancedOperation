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

public protocol OperationCondition {

  /// The name of the condition.
  var name: String { get }

  /// A flag to indicate whether this condition is mutually exclusive. Meaning that only one condition can be evaluated at a time.

  /// Other `Operation` instances which have this condition will wait in a `.pending` state - i.e. not get executed.
  var isMutuallyExclusive: Bool { get }

  func dependency(for operation: AdvancedOperation) -> Operation?

  /// Evaluate the condition, to see if it has been satisfied or not.
  ///
  /// - Parameters:
  ///   - operation: the `AdvancedOperation` which this condition is attached to.
  ///   - completion: a closure which receives an `OperationConditionResult`.
  func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void)
}

public extension OperationCondition {
  var isMutuallyExclusive: Bool { return false }
  func dependency(for operation: AdvancedOperation) -> Operation? { return nil }
}

internal extension OperationCondition {

  internal var category: String {
    return String(describing: type(of: self))
  }

}


// TODO, create a generic Result struct?
public enum OperationConditionResult {
  case satisfied
  case failed(Error)

  var error: Error? {
    if case .failed(let error) = self {
      return error
    }
    return nil
  }
}
