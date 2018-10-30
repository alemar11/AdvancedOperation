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

final public class ExclusivityManager { //TODO: implement cancel mode

  public static let sharedInstance = ExclusivityManager()

  /// The private queue used for thread safe operations.
  private lazy var queue = DispatchQueue(label: "\(identifier).\(type(of: self)).\(UUID().uuidString)")

  private var _queues: [QueueContainer] = []

  public init() { }

  internal func register(queue: AdvancedOperationQueue) {
    let results = _queues.filter { $0.queue?.identifier == queue.identifier }

    if results.isEmpty {
      let token = queue.observe(\.isSuspended, options: [.prior]) { [weak self] queue, change in
        print("⍟ \(String(describing: self)) \(change) - \(queue)")
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
      let conditions = operation.mutuallyExclusiveConditions

      guard !conditions.isEmpty else {
        return
      }

      self.register(queue: queue)

      /// Searches all the operations already enqueued for these categories in the current queue or in
      /// all the not suspended queues.
      //      let queues = _queues.compactMap { $0.queue }.filter { $0 === queue || !$0.isSuspended && !$0.operations.isEmpty }
      //
      //      guard !queues.isEmpty else {
      //        return
      //      }

      let queues = _queues.compactMap { $0.queue }.filter { $0 === queue || !$0.isSuspended && !$0.operations.isEmpty }

      let cancelConditions = conditions.filter { return $0.mutuallyExclusivityMode == .cancel }

      for condition in cancelConditions {
        let operations = searchAdvancedOperations(in: queues, forExclusivityName: condition.name).filter { $0 !== operation && !operation.dependencies.contains($0) && !$0.dependencies.contains(operation)}

        if !operations.isEmpty {
          operation.cancel()
          return
        }
      }

      let enqueueConditions = conditions.filter { return $0.mutuallyExclusivityMode == .enqueue }

      for condition in enqueueConditions {
        let operations = searchAdvancedOperations(in: queues, forExclusivityName: condition.name).filter { $0 !== operation && !operation.dependencies.contains($0) && !$0.dependencies.contains(operation) }
        //          operations.forEach { operation.addDependency($0) }
        //          operations.forEach({ ope in
        //            print("\t\t--> adding \(ope.operationName) as dependency for  \(operation.operationName)")
        //          })
        //print("\t\t--> adding \(operationForCategory.operationName) as dependency for  \(operation.operationName)")
        //operation.addDependency(operationForCategory)

        print("\n \(operation.operationName): found \(operations.count) operations for \(condition.name)")

        for operationForCategory in operations where operationForCategory !== operation {
          if !operation.dependencies.contains(operationForCategory) && !operationForCategory.dependencies.contains(operation) {
            print("\t\t--> 🔹 adding \(operationForCategory.operationName) as dependency for  \(operation.operationName)")
            operation.addDependency(operationForCategory)
          }
        }

      }
    }
  }

  //  private var advancedOperations: [AdvancedOperation] {
  //    let queues = _queues.compactMap { $0.queue }.filter { $0 === current_queue || !$0.isSuspended && !$0.operations.isEmpty }
  //
  //    guard !queues.isEmpty else {
  //      return []
  //    }
  //
  //    let operations = queues.flatMap { $0.operations }.compactMap { $0 as? AdvancedOperation }
  //    return operations
  //  }

  private func searchAdvancedOperations(in queues: [AdvancedOperationQueue], forExclusivityName category: String) -> [AdvancedOperation] {
    guard !queues.isEmpty else {
      return []
    }

    let advancedOperations = queues.flatMap { $0.operations }.compactMap { $0 as? AdvancedOperation }

    let operations = advancedOperations.filter { return $0.mutuallyExclusiveConditions.contains(where: { (condition) -> Bool in
      condition.name == category
    }) }

    return operations
  }

  /// Searches for all the operations with a given category in every **not** suspended queue.
  //  private func operationsForCategory(_ category: String) -> [AdvancedOperation] {
  //    //let operations = advancedOperations.filter { $0.executionConditions.compactMap { $0.name }.contains(category) }
  //    print(advancedOperations.count)
  //    let operations = advancedOperations.filter { return $0.exclusivityConditions.contains(where: { (condition) -> Bool in
  //      condition.name == category
  //    }) }
  //    return operations
  //  }

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
