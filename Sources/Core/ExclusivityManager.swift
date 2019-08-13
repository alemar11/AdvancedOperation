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

public final class ExclusivityManager {
  public static let shared = ExclusivityManager()

  /// The private queue used for thread safe operations.
  private let queue: DispatchQueue
  private let locksQueue: DispatchQueue
  private var _categories: [String: [DispatchGroup]] = [:]

  /// Creates a new `ExclusivityManager` instance.
  internal init(qos: DispatchQoS = .userInitiated) {
    // TODO qos probably shouldn't be changable, we need an high priority qos to avoid starvation
    // https://www.fivestars.blog/code/semaphores.html
    let label = "\(identifier).\(type(of: self)).\(UUID().uuidString)"
    self.queue = DispatchQueue(label: label, qos: qos)
    self.locksQueue = DispatchQueue(label: label + ".Locks", qos: qos, attributes: [.concurrent])
  }

  internal func lock(for categories: Set<ExclusivityMode>, completion: @escaping (Ticket?) -> Void) {
    guard !categories.isEmpty else {
      fatalError("A request for Mutual Exclusivity locks was made with no categories specified. This request is unnecessary.") // TODO
    }

    queue.async {
      self._lock(for: categories, completion: completion)
    }
  }


  internal struct Ticket {
    let categories: Set<ExclusivityMode>
  }

  private func _lock(for categories: Set<ExclusivityMode>, completion: @escaping (Ticket?) -> Void) {
    // check the status for cancellables categories
    let cancellations = categories.filter {
      if case .cancel = $0 {
        return true
      }
      return false
    }

    if !cancellations.isEmpty {
    let shouldBeCancelled = cancellations.map { $0.category }.reduce(true) { result, category in
      let status = _status(forCategory: category)
      return result && (status == .waitingForLock)
    }

    if shouldBeCancelled {
      completion(nil)
      return
    }
    }

    // start the mutual exclusivity lock
    let dipatchGroup = DispatchGroup()
    let ticket = Ticket(categories: categories)
    var notAvailableCategories = 0

    categories.forEach {
      let status = _lock(forCategory: $0.category, withGroup: dipatchGroup)
      switch status {
      case .available:
        print("💥", status, $0)
        break
      case .waitingForLock:
        print("💥", status, $0)
        notAvailableCategories += 1
      }
    }

    if notAvailableCategories == 0 {
      completion(ticket)
    } else {
      (0..<notAvailableCategories).forEach { _ in dipatchGroup.enter() }
      dipatchGroup.notify(queue: locksQueue) {
        completion(ticket)
      }
    }
  }

  private enum RequestLockResult {
    case available
    case waitingForLock
  }

  private func _status(forCategory category: String) -> RequestLockResult {
    let queuesByCategory = _categories[category] ?? []
    return queuesByCategory.isEmpty ? RequestLockResult.available : .waitingForLock
  }

  private func _lock(forCategory category: String, withGroup group: DispatchGroup) -> RequestLockResult {
    var queuesByCategory = _categories[category] ?? []
    let isFrontOfTheQueueForThisCategory = queuesByCategory.isEmpty
    queuesByCategory.append(group)
    _categories[category] = queuesByCategory
     return isFrontOfTheQueueForThisCategory ? RequestLockResult.available : .waitingForLock
  }


  internal func unlock(categories:Set<ExclusivityMode>) {
    queue.async { self._unlock(categories: categories) }
  }

  private func _unlock(categories: Set<ExclusivityMode>) {
    categories.forEach { _unlock(category: $0.category) }
  }

  internal func _unlock(category: String) {
    guard var queuesByCategory = _categories[category] else { return }
    // Remove the first item in the queue for this category
    // (which should be the operation that currently has the lock).
    assert(!queuesByCategory.isEmpty) // TODO

    _ = queuesByCategory.removeFirst()

    // If another operation is waiting on this particular lock
    if let nextOperationForLock = queuesByCategory.first {
      // Leave its DispatchGroup (i.e. it "acquires" the lock for this category)
      nextOperationForLock.leave()
    }

    if !queuesByCategory.isEmpty {
      _categories[category] = queuesByCategory
    } else {
      _categories.removeValue(forKey: category)
    }
  }

}

//internal final class ExclusivityManager {
//  /// Creates a new `ExclusivityManager` instance.
//  internal init(qos: DispatchQoS = .default) {
//    let label = "\(identifier).\(type(of: self)).\(UUID().uuidString)"
//    self.queue = DispatchQueue(label: label, qos: qos)
//  }
//
//  /// Running operations
//  internal var operations: [String: [Operation]] {
//    return queue.sync { return _operations }
//  }
//
//  /// The private queue used for thread safe operations.
//  private let queue: DispatchQueue
//
//  /// Holds all the running operations.
//  private var _operations: [String: [Operation]] = [:]
//
//  /// Adds an `AdvancedOperation` the the `ExclusivityManager` instance.
//  ///
//  /// - Parameters:
//  ///   - operation: The `AdvancedOperation` to add.
//  ///   - category: The category to identify an `AdvancedOperation`.
//  ///   - cancellable: True if the operation should be cancelled instead of enqueue if another operation with the same category exists.
//  internal func addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool = false) {
//    queue.sync {
//      self._addOperation(operation, category: category, cancellable: cancellable)
//    }
//  }
//
//  /// Removes an `AdvancedOperation` from the `ExclusivityManager` instance for a given `category`.
//  ///
//  /// - Parameters:
//  ///   - operation: The `AdvancedOperation` to remove.
//  ///   - category: The category to identify an `AdvancedOperation`.
//  internal func removeOperation(_ operation: AdvancedOperation, category: String) {
//    queue.async {
//      self._removeOperation(operation, category: category)
//    }
//  }
//
//  private func _addOperation(_ operation: AdvancedOperation, category: String, cancellable: Bool) {
//    guard !operation.isCancelled else { return }
//
//    let didFinishObserver = BlockObserver { [weak self] currentOperation, _ in
//      self?.removeOperation(currentOperation, category: category)
//    }
//    operation.addObserver(didFinishObserver)
//
//    var operationsWithThisCategory = _operations[category] ?? []
//    let previous = operationsWithThisCategory.last
//
//    if let previous = previous {
//      if cancellable {
//        // swiftlint:disable:next line_length
//        let error = AdvancedOperationError.executionCancelled(message: "The operation has been cancelled by the ExclusivityManager because there is already a running operation for the identifier: \(category).")
//        operation.cancel(error: error)
//        return // early exit because there is no need to add a cancelled operation to the manager
//      } else {
//        operation.addDependency(previous)
//      }
//    }
//
//    operationsWithThisCategory.append(operation)
//    _operations[category] = operationsWithThisCategory
//  }
//
//  private func _removeOperation(_ operation: AdvancedOperation, category: String) {
//    if
//      let operationsWithThisCategory = _operations[category],
//      let index = operationsWithThisCategory.firstIndex(of: operation)
//    {
//      var mutableOperationsWithThisCategory = operationsWithThisCategory
//      mutableOperationsWithThisCategory.remove(at: index)
//      _operations[category] = mutableOperationsWithThisCategory
//    }
//  }
//}
