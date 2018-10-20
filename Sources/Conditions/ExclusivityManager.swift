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

  static let exclusivityManagerKey = "ExclusivityManager"

  /// Creates a new `ExclusivityManager` instance.
  public init() { }

  /// The private queue used for thread safe operations.
  private lazy var queue = DispatchQueue(label: "\(identifier).\(type(of: self)).\(UUID().uuidString)")

  /// Holds all the running operations.
  private var _operations: [String: [Operation]] = [:]

  /// Running operations
  internal var operations: [String: [Operation]] {
    return queue.sync { return _operations }
  }

  internal var onOperationsChange: (([String: [Operation]]) -> Void)? = .none

  /// Adds an `AdvancedOperation` the the `ExclusivityManager` instance.
  ///
  /// - Parameters:
  ///   - operation: The `AdvancedOperation` to add.
  ///   - category: The category to identify an `AdvancedOperation`.
  ///   - cancellable: True if the operation should be cancelled instead of enqueue if another operation with the same category exists.
  internal func addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool = false) {
    _ = queue.sync {
      self._addOperation(operation, category: category, cancellable: cancellable)
      self.onOperationsChange?(self._operations)
    }
  }

  internal func removeOperation(_ operation: AdvancedOperation, category: String) {
    queue.async {
      self._removeOperation(operation, category: category)
      self.onOperationsChange?(self._operations)
    }
  }

  @discardableResult
  private func _addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool) -> Operation? {
    let didFinishObserver = BlockObserver {  [weak self] currentOperation, _ in
      self?.removeOperation(currentOperation, category: category)
    }
    operation.addObserver(didFinishObserver)

    var operationsWithThisCategory = _operations[category] ?? []
    let previous = operationsWithThisCategory.last

    if let previous = previous {
      if cancellable {
        let name = previous.name ?? "\(type(of: self))"
        let error = AdvancedOperationError.executionCancelled(
          message: "The operation has been cancelled by the ExclusivityManager because there is already an operation for the category: \(category) running.",
          userInfo: [type(of: self).exclusivityManagerKey: name]
        )

        operation.cancel(errors: [error])

        return previous // early exit because there is no need to add a cancelled operation to the manager
      } else {
        operation.addDependency(previous)
      }
    }

    operationsWithThisCategory.append(operation)
    _operations[category] = operationsWithThisCategory

    return previous
  }

  private func _removeOperation(_ operation: AdvancedOperation, category: String) {
    if
      let operationsWithThisCategory = _operations[category],
      let index = operationsWithThisCategory.index(of: operation)
    {
      var mutableOperationsWithThisCategory = operationsWithThisCategory
      mutableOperationsWithThisCategory.remove(at: index)
      _operations[category] = mutableOperationsWithThisCategory
    }
  }

}
