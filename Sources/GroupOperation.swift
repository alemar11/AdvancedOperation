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
  private let underlyingOperationQueue = AdvancedOperationQueue()

  /// Internal starting operation.
  private lazy var startingOperation = BlockOperation(block: { })

  /// Internal finishing operation.
  private lazy var finishingOperation: BlockOperation = {
    return BlockOperation { [weak self] in
      guard let `self` = self else { return }
      self.underlyingOperationQueue.isSuspended = true
      self.finish(errors: self.aggregatedErrors)
    }
  }()

  // MARK: - Initialization

  public convenience init(operations: Operation...) {
    self.init(operations: operations)
  }

  public init(operations: [Operation]) {
    super.init()

    isSuspended = true
    underlyingOperationQueue.delegate = self
    underlyingOperationQueue.addOperation(startingOperation)

    for operation in operations {
      addOperation(operation: operation)
    }
  }

  /// Cancels the execution of every operation.
  public final override func cancel(error: Error?) {
    // Cancels all the operations except the (internal) finishing one.
    for operation in underlyingOperationQueue.operations where operation !== finishingOperation {
      operation.cancel()
    }
    super.cancel(error: error)
  }

  open override func cancel() {
    cancel(error: nil)
  }

  public final override func main() {
    underlyingOperationQueue.isSuspended = false
    underlyingOperationQueue.addOperation(finishingOperation)
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

  public func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {}

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: Operation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else { return }
    guard !errors.isEmpty else { return }

    if operation !== finishingOperation || operation !== startingOperation {
      aggregatedErrors.append(contentsOf: errors)
    }
  }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) { }

  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) { }

}
