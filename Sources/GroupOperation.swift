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

open class GroupOperation: AdvancedOperation {

  // MARK: - Properties

  private let lock: NSLock = NSLock()

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

  /// Accesses the group operation queue's quality of service. It defaults to background quality.
  public final override var qualityOfService: QualityOfService {
    get {
      return underlyingOperationQueue.qualityOfService
    }
    set(value) {
      underlyingOperationQueue.qualityOfService = value
    }
  }

  /// Internal `AdvancedOperationQueue`.
  private let underlyingOperationQueue: AdvancedOperationQueue

  /// Internal starting operation.
  private lazy var startingOperation = AdvancedBlockOperation { complete in complete([]) } //TODO: test with normal block operation

  /// Internal finishing operation.
  private lazy var finishingOperation = AdvancedBlockOperation { complete in complete([]) }

  /// ExclusivityManager used by `AdvancedOperationQueue`.
  private let exclusivityManager: ExclusivityManager

  // MARK: - Initialization

  public convenience init(exclusivityManager: ExclusivityManager = .sharedInstance, operations: Operation...) {
    self.init(exclusivityManager: exclusivityManager, operations: operations)
  }

  public init(exclusivityManager: ExclusivityManager = .sharedInstance, operations: [Operation]) {
    self.exclusivityManager = exclusivityManager
    self.underlyingOperationQueue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)

    super.init()
    isSuspended = true
    underlyingOperationQueue.delegate = self

    finishingOperation.name = "Finishing Operation"
    finishingOperation.addDependency(startingOperation)
    finishingOperation.completionBlock = { [weak self] in
      // always executed
      guard let `self` = self else { return }
      self.isSuspended = true //TODO: self.isSupended = true
      self.finish(errors: self.aggregatedErrors)
    }

    startingOperation.name = "Starting Operation"
    underlyingOperationQueue.addOperation(startingOperation)

    for operation in operations {
      addOperation(operation: operation)
    }
  }

  /// Advises the `GroupOperation` object that it should stop executing its tasks.
  public final override func cancel(error: Error?) {
    guard !isCancelling && !isCancelled && !isFinished else { return }

    finishingOperation.addCompletionBlock(asEndingBlock: false) {
      // executed before the block defined in the initializer
      super.cancel(error: error)
    }

    startingOperation.cancel()
    for operation in underlyingOperationQueue.operations where operation !== finishingOperation && operation !== startingOperation {
      operation.cancel()
    }
    finishingOperation.cancel()
  }

  open override func cancel() {
    cancel(error: nil)
  }

  public final override func main() {
    underlyingOperationQueue.addOperation(finishingOperation)
    underlyingOperationQueue.isSuspended = false
  }

  public func addOperation(operation: Operation) {
    assert(!finishingOperation.isCancelled || !finishingOperation.isFinished, "The GroupOperation is finishing and cannot accept more operations.")
    
    finishingOperation.addDependency(operation)
    operation.addDependency(startingOperation)
    underlyingOperationQueue.addOperation(operation)
  }

  /// The maximum number of queued operations that can execute at the same time.
  /// - Note: Reducing the number of concurrent operations does not affect any operations that are currently executing.
  public final var maxConcurrentOperationCount: Int {
    get {
      return underlyingOperationQueue.maxConcurrentOperationCount
    }
    set {
      underlyingOperationQueue.maxConcurrentOperationCount = newValue
    }
  }

  /// A Boolean value indicating whether the GroupOpeation is actively scheduling operations for execution.
  public final var isSuspended: Bool {
    get {
      return underlyingOperationQueue.isSuspended
    }
    set {
      underlyingOperationQueue.isSuspended = newValue
    }
  }

}

extension GroupOperation: AdvancedOperationQueueDelegate {

  public func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "The GroupOperation is finished and cannot accept more operations.")

    // An operation is added to the group or an operation in this group has produced a new operation to execute.

    // make the finishing operation dependent on this newly-produced operation.
    if operation !== finishingOperation && !operation.dependencies.contains(finishingOperation){
      finishingOperation.addDependency(operation)
    }

    // All operations should be dependent on the "startingOperation". This way, we can guarantee that the conditions for other operations
    // will not evaluate until just before the operation is about to run. Otherwise, the conditions could be evaluated at any time, even
    // before the internal operation queue is unsuspended.
    if operation !== startingOperation && !operation.dependencies.contains(startingOperation) {
      operation.addDependency(startingOperation)
    }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: Operation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else { return }
    
    guard operation !== finishingOperation && operation !== startingOperation else { return }

    if !errors.isEmpty {
      aggregatedErrors.append(contentsOf: errors)
    }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) { }

}
