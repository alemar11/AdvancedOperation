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

final public class ExclusivityManager {

  public static let sharedInstance = ExclusivityManager()

  /// Creates a new `ExclusivityManager` instance.
  public init() { }

  private lazy var queue = DispatchQueue(label: "\(identifier).\(type(of: self)).\(UUID().uuidString)")

  internal private(set) var operations: [String: [Operation]] = [:]

  /// Adds an `AdvancedOperation` the the `ExclusivityManager` instance.
  ///
  /// - Parameters:
  ///   - operation: The `AdvancedOperation` to add.
  ///   - category: The category to identify an `AdvancedOperation`.
  ///   - cancellable: True if the operation should be cancelled instead of enqueue if another operation with the same category exists.
  internal func addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool = false) {
    _ = queue.sync(execute: {
      self._addOperation(operation, category: category, cancellable: cancellable)
    })
  }

  internal func removeOperation(_ operation: AdvancedOperation, category: String) {
    queue.async {
      self._removeOperation(operation, category: category)
    }
  }

  @discardableResult
  private func _addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool) -> Operation? {
    let didFinishObserver = BlockObserver {  [unowned self] currentOperation, _ in
      self.removeOperation(currentOperation, category: category)
    }
    operation.addObserver(didFinishObserver)

    var operationsWithThisCategory = operations[category] ?? []
    let previous = operationsWithThisCategory.last

    if let previous = previous {
      if cancellable {
        let error = NSError(
          domain: "\(identifier).\(type(of: self)).\(category)",
          code: OperationErrorCode.executionCancelled.rawValue,
          userInfo: nil)

        operation.cancel(error: error)
      } else {
        operation.addDependency(previous)
      }
    }

    operationsWithThisCategory.append(operation)
    operations[category] = operationsWithThisCategory

    return previous
  }

  private func _removeOperation(_ operation: AdvancedOperation, category: String) {
    if
      let operationsWithThisCategory = operations[category],
      let index = operationsWithThisCategory.index(of: operation)
    {
      var mutableOperationsWithThisCategory = operationsWithThisCategory
      mutableOperationsWithThisCategory.remove(at: index)
      operations[category] = mutableOperationsWithThisCategory
    }
  }
}
