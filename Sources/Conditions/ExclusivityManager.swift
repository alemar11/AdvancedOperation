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

  /// The private queue used for thread safe operations.
  private lazy var queue = DispatchQueue(label: "\(identifier).\(type(of: self)).\(UUID().uuidString)")

  private var _queues: [QueueContainer] = []

  public init() { }

  internal func register(queue: AdvancedOperationQueue) {
      let results = _queues.filter { $0.queue?.identifier == queue.identifier }

      if results.isEmpty {
        let token = queue.observe(\.isSuspended, options: [.prior]) { [weak self] queue, change in
        print("🚩 \(String(describing: self)) \(change) - \(queue)")
          // is suspended:
          // check all the other queues and remove all the dependencies of this queue

          // not suspended
          // get all mutual exclusivity operation and set the dependencers
        }

        let container = QueueContainer(queue: queue, token: token)
        _queues.append(container)
      }
  }

  internal func unregister(queue: AdvancedOperationQueue) {
    self.queue.sync {
      _queues.removeAll { $0.queue?.identifier == queue.identifier }
    }
  }

  // is suspended remove the dependencies
  //  private func xxx(queue: Queue, category: String) {
  //    guard let advancedQueue = queue.queue else {
  //      return
  //    }
  //
  //    let exclusivities = advancedQueue.operations.filter { $0 is MutualExclusivityOperation }.compactMap { $0 as? MutualExclusivityOperation}
  //
  //    guard !exclusivities.isEmpty else {
  //      return
  //    }
  //
  //    let remainingQueues = _queues.filter { $0.queue?.identifier != queue.queue?.identifier }
  //
  //    let operations = remainingQueues.compactMap { $0.queue?.operations }.flatMap { $0 }.compactMap { $0 as? MutualExclusivityOperation}
  //
  //
  //    for operation in operations {
  //      for exclusivity in exclusivities {
  //        if operation.category == exclusivity.category {
  //          operation.removeDependency(exclusivity)
  //        }
  //      }
  //    }
  //  }
  //
  //  // if not suspended re-add dependencies
  //  private func yyy(queue: AdvancedOperationQueue, category: String) {
  //
  //  }

  internal func addOperation(_ operation: AdvancedOperation, for queue: AdvancedOperationQueue) {
    self.queue.sync {
      let categories = operation.categories

      guard !categories.isEmpty else {
        return
      }

      self.register(queue: queue)

      /// Searches all the operations already enqueued for these categories in the current queue or in
      /// all the not suspended queues.
      let queues = _queues.compactMap { $0.queue }.filter { $0 === queue || !$0.isSuspended && !$0.operations.isEmpty }

      guard !queues.isEmpty else {
        return
      }

      let allOperations = queues.flatMap { $0.operations }
      let advancedOperations = allOperations.compactMap { $0 as? AdvancedOperation }
      let operations = advancedOperations.filter { $0.categories.contains(where: categories.contains) }
      print("🔴 found \(operations.count) for categories: \(categories)")

      for ope in operations where ope !== operation {
        if !operation.dependencies.contains(ope) {
          print("\t\t--> adding \(ope.operationName) as dependency for  \(operation.operationName)")
          operation.addDependency(ope)
        }
      }
    }
  }

}

private final class QueueContainer {
  let token: NSKeyValueObservation
  weak var queue: AdvancedOperationQueue?

  init(queue: AdvancedOperationQueue, token: NSKeyValueObservation) {
    self.queue = queue
    self.token = token
  }

  deinit {
    token.invalidate()
  }
}
