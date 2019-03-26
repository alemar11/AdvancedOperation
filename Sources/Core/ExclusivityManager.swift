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

internal final class ExclusivityManager {

  /// Creates a new `ExclusivityManager` instance.
  internal init(qos: DispatchQoS = .default) {
    let label = "\(identifier).\(type(of: self)).\(UUID().uuidString)"
    self.queue = DispatchQueue(label: label, qos: qos)
  }

  /// Running operations
  internal var operations: [String: [Operation]] {
    return queue.sync { return _operations }
  }

  /// The private queue used for thread safe operations.
  private let queue: DispatchQueue

  /// Holds all the running operations.
  private var _operations: [String: [Operation]] = [:]

  /// Adds an `AdvancedOperation` the the `ExclusivityManager` instance.
  ///
  /// - Parameters:
  ///   - operation: The `AdvancedOperation` to add.
  ///   - category: The category to identify an `AdvancedOperation`.
  ///   - cancellable: True if the operation should be cancelled instead of enqueue if another operation with the same category exists.
  internal func addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool = false) {
    queue.sync {
      self._addOperation(operation, category: category, cancellable: cancellable)
    }
  }

  internal func removeOperation(_ operation: AdvancedOperation, category: String) {
    queue.async {
      self._removeOperation(operation, category: category)
    }
  }

  private func _addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool) {
    guard !operation.isCancelled else { return }

    let didFinishObserver = BlockObserver {  [weak self] currentOperation, _ in
      self?.removeOperation(currentOperation, category: category)
    }
    operation.addObserver(didFinishObserver)

    var operationsWithThisCategory = _operations[category] ?? []
    let previous = operationsWithThisCategory.last

    if let previous = previous {
      if cancellable {
        // swiftlint:disable:next line_length
        let error = AdvancedOperationError.executionCancelled(message: "The operation has been cancelled by the ExclusivityManager because there is already a running operation for the identifier: \(category).")

        operation.cancel(errors: [error])
        return // early exit because there is no need to add a cancelled operation to the manager
      } else {
        operation.addDependency(previous)
      }
    }

    operationsWithThisCategory.append(operation)
    _operations[category] = operationsWithThisCategory
  }

  private func _removeOperation(_ operation: AdvancedOperation, category: String) {
    if
      let operationsWithThisCategory = _operations[category],
      let index = operationsWithThisCategory.firstIndex(of: operation)
    {
      var mutableOperationsWithThisCategory = operationsWithThisCategory
      mutableOperationsWithThisCategory.remove(at: index)
      _operations[category] = mutableOperationsWithThisCategory
    }
  }
}
