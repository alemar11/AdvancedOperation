//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
//

import Foundation

extension Operation {
  /// Returns the `Operation` name or its type if the name is nil.
  public var operationName: String { name ?? "\(type(of: self))" }

  /// Returns `true` if **at least one** dependency has been cancelled.
  public var hasSomeCancelledDependencies: Bool { dependencies.hasSomeCancelledOperations }

  /// Adds multiple dependencies to the operation.
  /// If the receiver is already executing its task, adding dependencies has no practical effect.
  public func addDependencies(_ dependencies: [Operation]) {
    for dependency in dependencies {
      addDependency(dependency)
    }
  }

  /// Adds multiple dependencies to the operation.
  /// If the receiver is already executing its task, adding dependencies has no practical effect.
  public func addDependencies(_ dependencies: Operation...) {
    addDependencies(dependencies)
  }

  /// Removes all the dependencies.
  public func removeDependencies() {
    for dependency in dependencies {
      removeDependency(dependency)
    }
  }
}

extension Sequence where Element: Operation {
  /// Makes every operation in the sequence dependent on the completion of the specified operations.
  public func addDependencies(_ dependencies: Operation...) {
    addDependencies(dependencies)
  }

  /// Makes every operation in the sequence dependent on the completion of the specified operations.
  public func addDependencies(_ dependencies: [Operation]) {
    forEach { $0.addDependencies(dependencies) }
  }
}

extension OperationQueue {
  /// Creates a serial OperationQueue.
  public static func serial() -> OperationQueue {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }
}

extension Collection where Element: Operation {
  /// Returns `true` if **at least one** operation has been cancelled.
  fileprivate var hasSomeCancelledOperations: Bool { first { $0.isCancelled } != nil }
}
