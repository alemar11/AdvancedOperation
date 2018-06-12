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

  /// Indicates how this condition is mutually exclusive.
  var mutuallyExclusivityMode: MutualExclusivityMode { get }

  /// Some conditions may have the ability to satisfy the condition if another operation is executed first.
  ///
  /// - Parameter operation: The `AdvancedOperation` to which the Condition has been added.
  /// - Returns: An `Operation`, if a dependency should be automatically added. Otherwise, `nil`.
  /// - Note: Only a single operation may be returned as a dependency. If you find that you need to return multiple operations, then you should be expressing that as multiple conditions.
  ///         Alternatively, you could return a single `GroupOperation` that executes multiple operations internally.
  func dependency(for operation: AdvancedOperation) -> Operation?

  /// Evaluate the condition, to see if it has been satisfied or not.
  ///
  /// - Parameters:
  ///   - operation: the `AdvancedOperation` which this condition is attached to.
  ///   - completion: a closure which receives an `OperationConditionResult`.
  func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void)
}

public extension OperationCondition {

  var mutuallyExclusivityMode: MutualExclusivityMode { return .disabled }

  func dependency(for operation: AdvancedOperation) -> Operation? { return nil }
}

public extension OperationCondition {

  public var name: String {
    return String(describing: type(of: self))
  }

}
