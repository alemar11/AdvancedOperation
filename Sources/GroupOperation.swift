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

  // MARK: - Properties

  public override func useOSLog(_ log: OSLog) {
    super.useOSLog(log)
    underlyingOperationQueue.operations.forEach { operation in
      if let advancedOperation = operation as? AdvancedOperation, advancedOperation.log === OSLog.disabled {
        advancedOperation.useOSLog(log)
      }
    }
  }

  /// Stores all of the `AdvancedOperation` errors during the execution.
  internal private(set) var aggregatedErrors: [Error] {
    get {
      return lock.synchronized { _aggregatedErrors }
    }
    set {
      lock.synchronized {
        _aggregatedErrors = newValue
      }
    }
  }

  private var _aggregatedErrors = [Error]()

  /// Internal `AdvancedOperationQueue`.
  private let underlyingOperationQueue: AdvancedOperationQueue

  /// Internal starting operation.
  private lazy var startingOperation = BlockOperation { }

  /// Internal finishing operation.
  private lazy var finishingOperation = BlockOperation { }

  private let lock = NSLock()

  private var _temporaryCancelErrors = [Error]()

  private var _cancellationTriggered = false

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

  // MARK: - Initialization

  /// Creates a `GroupOperation`instance.
  ///
  /// - Parameters:
  ///   - operations: The operations of which the `GroupOperation` is composed of.
  ///   - qualityOfService: The default service level to apply to operations executed using the queue.
  ///   - maxConcurrentOperationCount: The maximum number of queued operations that can execute at the same time.
  ///   - underlyingQueue: An optional DispatchQueue which defaults to nil, this parameter is set as the underlying queue of the group's own `AdvancedOperationQueue`.
  /// - Note: If the operation object has an explicit quality of service level set, that value is used instead.
  public convenience init(operations: Operation...,
                          qualityOfService: QualityOfService = .default,
                          maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                          underlyingQueue: DispatchQueue? = .none) {
    self.init(operations: operations,
              qualityOfService: qualityOfService,
              maxConcurrentOperationCount: maxConcurrentOperationCount,
              underlyingQueue: underlyingQueue)
  }

  /// Creates a `GroupOperation`instance.
  ///
  /// - Parameters:
  ///   - operations: The operations of which the `GroupOperation` is composed of.
  ///   - qualityOfService: The default service level to apply to operations executed using the queue.
  ///   - maxConcurrentOperationCount: The maximum number of queued operations that can execute at the same time.
  ///   - underlyingQueue: An optional DispatchQueue which defaults to nil, this parameter is set as the underlying queue of the group's own `AdvancedOperationQueue`.
  /// - Note: If the operation object has an explicit quality of service level set, that value is used instead.
  public init(operations: [Operation],
              qualityOfService: QualityOfService = .default,
              maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount,
              underlyingQueue: DispatchQueue? = .none) {
    let queue = AdvancedOperationQueue()
    queue.underlyingQueue = underlyingQueue
    queue.qualityOfService = qualityOfService
    queue.maxConcurrentOperationCount = maxConcurrentOperationCount
    queue.isSuspended = true
    self.underlyingOperationQueue = queue // TODO: EXC_BAD_ACCESS possible fix

    super.init()

    self.underlyingOperationQueue.delegate = self
    self.startingOperation.name = "Start<\(operationName)>"
    self.underlyingOperationQueue.addOperation(startingOperation)
    self.finishingOperation.name = "End<\(operationName)>"
    self.finishingOperation.addDependency(startingOperation)
    self.underlyingOperationQueue.addOperation(finishingOperation)

    for operation in operations {
      addOperation(operation: operation)
    }
  }

  deinit {
    self.underlyingOperationQueue.delegate = nil
  }

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

    // TODO
    // find opeartion not executing, reverse the order (hoping that they are enqueue in a serial way) --> cancel
    // find operation executing, reverse the order -> cancel and wait

    /// once all the operations will be cancelled and then finished, the finishing operation will be called

    if !isExecuting && !isFinished {
      // if it's ready or pending (waiting for depedencies)
      queueLock.synchronized {
        underlyingOperationQueue.isSuspended = false
      }
    }

  }

  open override func cancel() {
    cancel(errors: [])
  }

  /// Performs the receiver’s non-concurrent task.
  /// - Note: If overridden, be sure to call the parent `main` as the **end** of the new implementation.
  open override func main() {
    // if it's cancelling, the finish command we be called automatically
    if lock.synchronized({ _cancellationTriggered }) && !isCancelled {
      return
    }

    if isCancelled {
      finish()
      return
    }

    queueLock.synchronized {
      if !_suspended {
        underlyingOperationQueue.isSuspended = false
      }
    }
  }

  open override func finish(errors: [Error] = []) {
    queueLock.synchronized {
      underlyingOperationQueue.isSuspended = true
    }
    super.finish(errors: errors)
  }

  public func addOperation(operation: Operation) {
    assert(!finishingOperation.isCancelled || !finishingOperation.isFinished, "The GroupOperation is finishing and cannot accept more operations.")

    finishingOperation.addDependency(operation)
    operation.addDependency(startingOperation)
    underlyingOperationQueue.addOperation(operation)

    if let advancedOperation = operation as? AdvancedOperation, advancedOperation.log === OSLog.disabled {
      advancedOperation.useOSLog(log)
    }
  }

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

  /// Lock to manage the underlyingOperationQueue isSuspended property.
  private let queueLock = NSLock()

  private var _suspended = false

  /// A Boolean value indicating whether the GroupOpeation is actively scheduling operations for execution.
  public final var isSuspended: Bool {
    get {
      return queueLock.synchronized { _suspended }
    }
    set {
      queueLock.synchronized {
        underlyingOperationQueue.isSuspended = newValue
        _suspended = newValue
      }
    }
  }

  /// This property specifies the service level applied to operation objects added to the `GroupOperation`. (It defaults to the `default` quality.)
  /// If the operation object has an explicit service level set, that value is used instead.
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

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: AdvancedOperation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else {
      return
    }

    guard operation !== finishingOperation && operation !== startingOperation else {
      assertionFailure("There shouldn't be Operations but only AdvancedOperations in this delegate implementation call.")
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

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: AdvancedOperation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: AdvancedOperation, withErrors errors: [Error]) { }

}
