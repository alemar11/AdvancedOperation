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
import os.log

open class GroupOperation: AdvancedOperation {

  // MARK: - Public Properties

  /// ExclusivityManager used by `AdvancedOperationQueue`.
  public let exclusivityManager: ExclusivityManager

  // MARK: - Private Properties

  /// Internal `AdvancedOperationQueue`.
  private let underlyingOperationQueue: AdvancedOperationQueue

  /// Internal starting operation.
  private lazy var startingOperation = BlockOperation { }

  /// Internal finishing operation.
  private lazy var finishingOperation = BlockOperation { }

  private let lock = NSLock()

  private var _temporaryCancelErrors = [Error]()

  /// Holds the cancellation error.
  private var temporaryCancelErrors: [Error] {
    get {
      return lock.synchronized { _temporaryCancelErrors }
    }
    set {
      lock.synchronized {
        _temporaryCancelErrors = newValue
      }
    }
  }

  private var _aggregatedErrors = [Error]()

  /// Stores all of the `AdvancedOperation` errors during the execution.
  internal var aggregatedErrors: [Error] {
    get {
      return lock.synchronized { _aggregatedErrors }
    }
    set {
      lock.synchronized {
        _aggregatedErrors = newValue
      }
    }
  }

  public override func useOSLog(_ log: OSLog) {
    super.useOSLog(log) //TODO improve this for addOperation
    underlyingOperationQueue.operations.forEach { operation in
      if let advancedOperation = operation as? AdvancedOperation {
        advancedOperation.useOSLog(log)
      }
    }
  }

  // MARK: - Initialization

  /// Creates a `GroupOperation`instance.
  ///
  /// - Parameters:
  ///   - operations: The operations of which the `GroupOperation` is composed of.
  ///   - exclusivityManager: An instance of `ExclusivityManager`.
  ///   - underlyingQueue: An optional DispatchQueue which defaults to nil, this parameter is set as the underlying queue of the group's own `AdvancedOperationQueue`.
  public convenience init(operations: Operation..., exclusivityManager: ExclusivityManager = .sharedInstance, underlyingQueue: DispatchQueue? = .none) {
    self.init(operations: operations, exclusivityManager: exclusivityManager, underlyingQueue: underlyingQueue)
  }

  /// Creates a `GroupOperation`instance.
  ///
  /// - Parameters:
  ///   - operations: The operations of which the `GroupOperation` is composed of.
  ///   - exclusivityManager: An instance of `ExclusivityManager`.
  ///   - underlyingQueue: An optional DispatchQueue which defaults to nil, this parameter is set as the underlying queue of the group's own `AdvancedOperationQueue`.
  public init(operations: [Operation], exclusivityManager: ExclusivityManager = .sharedInstance, underlyingQueue: DispatchQueue? = .none) {
    self.exclusivityManager = exclusivityManager
    self.underlyingOperationQueue = AdvancedOperationQueue(exclusivityManager: exclusivityManager, underlyingQueue: underlyingQueue)

    super.init()

    isSuspended = true
    underlyingOperationQueue.delegate = self //TODO lock?

    startingOperation.name = "StartingOperation<\(operationName)>"
    underlyingOperationQueue.addOperation(startingOperation)

    finishingOperation.name = "FinishingOperation<\(operationName)>"
    finishingOperation.addDependency(startingOperation)
    underlyingOperationQueue.addOperation(finishingOperation)

    for operation in operations {
      addOperation(operation: operation)
    }
  }

  private var _cancellationTriggered = false

  /// Advises the `GroupOperation` object that it should stop executing its tasks.
  public final override func cancel(errors: [Error]) {
    let canBeCancelled = lock.synchronized { () -> Bool in
      if _cancellationTriggered {
        return false
      } else {
        _cancellationTriggered = true
        _temporaryCancelErrors = errors
        return true
      }
    }

    guard canBeCancelled else {
      return
    }

    guard !isCancelled && !isFinished else {
      return
    }

    for operation in underlyingOperationQueue.operations where operation !== finishingOperation && operation !== startingOperation && !operation.isFinished && !operation.isCancelled {
      operation.cancel()
    }

    /// once all the operations will be cancelled and then finished, the finishing operation will be called

    /// every operation is finished after a cancellation
    if isReady {
      isSuspended = false
    }

//    if isReady {
//      run()
//    }
  }

  open override func cancel() {
    cancel(errors: [])
  }

  /// Performs the receiver’s non-concurrent task.
  /// - Note: If overridden, be sure to call the parent `main` as the **end** of the new implementation.
  open override func main() {
    if isCancelled {
      finish()
      return
    }

    isSuspended = false
  }

  open override func finish(errors: [Error] = []) {
    isSuspended = true
    super.finish(errors: errors)
  }

  public func addOperation(operation: Operation) {
    assert(!finishingOperation.isCancelled || !finishingOperation.isFinished, "The GroupOperation is finishing and cannot accept more operations.")

    finishingOperation.addDependency(operation)
    operation.addDependency(startingOperation)
    underlyingOperationQueue.addOperation(operation)
  }

  /// Lock to manage the underlyingOperationQueue properties.
  private let queueLock = NSLock()

  /// The maximum number of queued operations that can execute at the same time.
  /// - Note: Reducing the number of concurrent operations does not affect any operations that are currently executing.
  public final var maxConcurrentOperationCount: Int {
    get {
      return queueLock.synchronized { underlyingOperationQueue.maxConcurrentOperationCount }
    }
    set {
      queueLock.synchronized {
        underlyingOperationQueue.maxConcurrentOperationCount = newValue
      }
    }
  }

  /// A Boolean value indicating whether the GroupOpeation is actively scheduling operations for execution.
  @objc
  public final var isSuspended: Bool {
    get {
      return queueLock.synchronized { underlyingOperationQueue.isSuspended }
    }
    set {
      queueLock.synchronized {
        underlyingOperationQueue.isSuspended = newValue
      }
    }
  }

  /// Accesses the group operation queue's quality of service. It defaults to background quality.
  public final override var qualityOfService: QualityOfService {
    get {
      return queueLock.synchronized { underlyingOperationQueue.qualityOfService }
    }
    set(value) {
      queueLock.synchronized { underlyingOperationQueue.qualityOfService = value }
    }
  }

}

extension GroupOperation: AdvancedOperationQueueDelegate {

  public func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "The GroupOperation is finished and cannot accept more operations.")

    /// An operation is added to the group or an operation in this group has produced a new operation to execute.

    /// make the finishing operation dependent on this newly-produced operation.
    if operation !== finishingOperation && !operation.dependencies.contains(finishingOperation) {
      finishingOperation.addDependency(operation)
    }

    /// All operations should be dependent on the "startingOperation". This way, we can guarantee that the conditions for other operations
    /// will not evaluate until just before the operation is about to run. Otherwise, the conditions could be evaluated at any time, even
    /// before the internal operation queue is unsuspended.
    if operation !== startingOperation && !operation.dependencies.contains(startingOperation) {
      operation.addDependency(startingOperation)
    }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: Operation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else {
      return
    }

    guard operation !== finishingOperation && operation !== startingOperation else {
      return
    }

    if !errors.isEmpty { // avoid TSAN _swiftEmptyArrayStorage
      aggregatedErrors.append(contentsOf: errors)
    }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else {
      return
    }

    if operation === finishingOperation {
      let allOperationsCancelled = lock.synchronized { _cancellationTriggered }
      if allOperationsCancelled {
        super.cancel(errors: temporaryCancelErrors)
        finish()
      } else {
        finish(errors: self.aggregatedErrors)
    }
  }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) { }

}
