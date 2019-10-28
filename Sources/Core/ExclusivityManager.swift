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
  public final class Token {
    public let categories: Set<String>
    private var unlockClosure: ((Set<String>) -> Void)?

    fileprivate init(categories: Set<String>, unlockClosure: @escaping (Set<String>) -> Void) {
      self.categories = categories
      self.unlockClosure = unlockClosure
    }

    public func unlock() {
      unlockClosure?(categories)
      unlockClosure = nil // the token is consumed and cannot be used again
    }
  }

  public static let shared = ExclusivityManager()

  private enum Exclusivity {
    case available
    case notAvailable
  }

  let dispatchGroupsQueue: DispatchQueue
  /// The private queue used for thread safe operations.
  private let queue: DispatchQueue = DispatchQueue(label: "\(identifier).ExclusivityManager", qos: .userInteractive) //an high priority qos is needed to avoid thread starvation
  private var categories: [String: [DispatchGroup]] = [:]

  /// Creates a new `ExclusivityManager` instance.
  internal init(qos: DispatchQoS = .userInteractive) {
    // https://www.fivestars.blog/code/semaphores.html
    dispatchGroupsQueue = DispatchQueue(label: "\(identifier).ExclusivityManager.DispatchGroupsQueue.\(UUID().uuidString)", qos: qos, attributes: [.concurrent])
  }

  public func lock(for categories: Set<String>, onAvailability completion: @escaping (Token) -> Void) {
    queue.async {
      self._lock(for: categories, completion: completion)
    }
  }

  private func _lock(for categories: Set<String>, completion: @escaping (Token) -> Void) {
    let dipatchGroup = DispatchGroup()
    let token = Token(categories: categories) { [weak self] categories in
      self?.unlock(categories: categories)
    }

    let notAvailableCategoriesCount = categories.map { registerDispatchGroup(dipatchGroup, forCategory: $0) }
    .filter { $0 == .notAvailable }
    .count

    if notAvailableCategoriesCount == 0 {
      // the item is free to acquire the exclusivity lock without waiting
      completion(token)
    } else {
      // the item requesting the exclusivity lock will wait until the group is empty
      (0..<notAvailableCategoriesCount).forEach { _ in dipatchGroup.enter() }
      // only then the completion block will be called
      dipatchGroup.notify(queue: dispatchGroupsQueue) {
        completion(token)
      }
    }
  }

  /// Associates a DispatchGroup with a category and returns the exclusivity state for that category.
  private func registerDispatchGroup(_ group: DispatchGroup, forCategory category: String) -> Exclusivity {
    var groupsByCategory = categories[category] ?? []
    let isCategoryAvailable = groupsByCategory.isEmpty
    groupsByCategory.append(group)
    categories[category] = groupsByCategory
    return isCategoryAvailable ? .available : .notAvailable
  }

  private func unlock(categories: Set<String>) {
    queue.async {
      categories.forEach { self.unlock(category: $0) }
    }
  }

  private func unlock(category: String) {
    guard var groupsByCategory = categories[category], !groupsByCategory.isEmpty else {
      return
    }

    //assert(!groupsByCategory.isEmpty, "The queue for the \(category) category is already empty.")

    // Removes the first item (that has currently the exclusivity lock) for this category.
    _ = groupsByCategory.removeFirst()

    // If there is an item waiting for this category
    if let nextDispatchGroup = groupsByCategory.first {
      // leave its DispatchGroup (it "acquires" the exclusivity lock for this category)
      nextDispatchGroup.leave()
    }

    if !groupsByCategory.isEmpty {
      categories[category] = groupsByCategory
    } else {
      categories.removeValue(forKey: category)
    }
  }
}
