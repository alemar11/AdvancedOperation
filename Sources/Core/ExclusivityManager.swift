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

public final class ExclusivityManager2 {
  public struct Token {
    public let categories: Set<String>
    private var unlockClosure: (Set<String>) -> Void

    fileprivate init(categories: Set<String>, unlockClosure: @escaping (Set<String>) -> Void) {
      self.categories = categories
      self.unlockClosure = unlockClosure
    }

    public func unlock() {
      unlockClosure(categories)
    }
  }

  public static let shared = ExclusivityManager2()

  let dispatchGroupQueue: DispatchQueue
  /// The private queue used for thread safe operations.
  private let queue: DispatchQueue = DispatchQueue(label: "TODO", qos: .userInteractive) //an high priority qos is needed to avoid thread starvation
  private var _categories: [String: [DispatchGroup]] = [:]

  /// Creates a new `ExclusivityManager` instance.
  internal init(qos: DispatchQoS = .userInteractive) {
    // https://www.fivestars.blog/code/semaphores.html
    let label = "\(identifier).\(type(of: self)).\(UUID().uuidString)"
    dispatchGroupQueue = DispatchQueue(label: label + ".DispatchGroup", qos: qos, attributes: [.concurrent])
  }

  public func lock(for categoris: Set<String>, onAvailability completion: @escaping (Token) -> Void) {
    queue.async {
    }
  }

  private func unlock(categories: Set<ExclusivityCategory>) {
    queue.async {
    }
  }
}

/// `ExclusivityManager` manages exclusivity locks.
public final class ExclusivityManager {
  /// A shared ExclusivityManager instance (per-process) that can be used accross multiple AdvanceOperations.
  public static let shared = ExclusivityManager()

  /// Mutual exclusivity ticket.
  internal struct Ticket {
    let categories: Set<ExclusivityCategory>
  }

  /// Mutual exclusivity lock request status.
  private enum LockRequest {
    case available
    case waiting
  }

  /// The private queue used for thread safe operations.
  private let queue: DispatchQueue
  private let locksQueue: DispatchQueue
  private var _categories: [String: [DispatchGroup]] = [:]

  /// Creates a new `ExclusivityManager` instance.
  internal init(qos: DispatchQoS = .userInitiated) {
    // https://www.fivestars.blog/code/semaphores.html
    let label = "\(identifier).\(type(of: self)).\(UUID().uuidString)"
    self.queue = DispatchQueue(label: label, qos: .userInitiated) //an high priority qos is needed to avoid thread starvation
    self.locksQueue = DispatchQueue(label: label + ".Locks", qos: qos, attributes: [.concurrent])
  }

  internal func lock(for categories: Set<ExclusivityCategory>, completion: @escaping (Ticket?) -> Void) {
    precondition(!categories.isEmpty, "A mutual exclusivity lock request has been made without no categories specified.")

    queue.async {
      self._lock(for: categories, completion: completion)
    }
  }

  private func _lock(for categories: Set<ExclusivityCategory>, completion: @escaping (Ticket?) -> Void) {
    // check the status for cancellables categories
    let cancellations = categories.filter {
      if case .cancel = $0 {
        return true
      }
      return false
    }

    if !cancellations.isEmpty {
      let shouldBeCancelled = cancellations.map { $0.category }.allSatisfy { category -> Bool in
        let status = _status(forCategory: category)
        return status == .waiting
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
        break
      case .waiting:
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

  private func _status(forCategory category: String) -> LockRequest {
    let queuesByCategory = _categories[category] ?? []
    return queuesByCategory.isEmpty ? LockRequest.available : .waiting
  }

  private func _lock(forCategory category: String, withGroup group: DispatchGroup) -> LockRequest {
    var queuesByCategory = _categories[category] ?? []
    let isFrontOfTheQueueForThisCategory = queuesByCategory.isEmpty
    queuesByCategory.append(group)
    _categories[category] = queuesByCategory
    return isFrontOfTheQueueForThisCategory ? LockRequest.available : .waiting
  }

  internal func unlock(categories: Set<ExclusivityCategory>) {
    queue.async { self._unlock(categories: categories) }
  }

  private func _unlock(categories: Set<ExclusivityCategory>) {
    categories.forEach { _unlock(category: $0.category) }
  }

  private func _unlock(category: String) {
    guard var queuesByCategory = _categories[category] else { return }
    // Remove the first item in the queue for this category
    // (which should be the operation that currently has the lock).
    assert(!queuesByCategory.isEmpty, "The queue for the \(category) category is already empty.")

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
