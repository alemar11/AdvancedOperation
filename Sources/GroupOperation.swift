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

public final class GroupOperation: AdvancedOperation {

  // MARK: - Properties

  private let lock: NSLock = NSLock()

  private var _aggregatedErrors = [Error]()

  /// Stores all of the `AdvancedOperation` errors during the execution.
  internal var aggregatedErrors: [Error] {
    get {
      lock.lock()
      let result = _aggregatedErrors
      lock.unlock()
      return result
    }
    set(value) {
      lock.lock()
      _aggregatedErrors = value
      lock.unlock()
    }
  }

  private var _qualityOfService = QualityOfService.default

  /// Accesses the group operation queue's quality of service. It defaults to background quality.
  public final override var qualityOfService: QualityOfService {
    get {
      return _qualityOfService
    }
    set(value) {
      _qualityOfService = value
      underlyingOperationQueue.qualityOfService = _qualityOfService
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

    underlyingOperationQueue.isSuspended = true
    underlyingOperationQueue.delegate = self
    underlyingOperationQueue.addOperation(startingOperation)

    for operation in operations {
      addOperation(operation: operation)
    }

  }

  /// Cancels the execution of every operation.
  public override final func cancel() {
    // Cancels all the operations except the (internal) finishing one.
    for operation in underlyingOperationQueue.operations where operation !== finishingOperation {
      operation.cancel()
    }
    super.cancel()
  }

  public final override func main() {
    underlyingOperationQueue.isSuspended = false
    underlyingOperationQueue.addOperation(finishingOperation)
  }

  //TODO: test
  public func addOperation(operation: Operation) {
    assert(!finishingOperation.isCancelled || !finishingOperation.isFinished, "The GroupOperation is finishing and cannot accept more operations.")

    finishingOperation.addDependency(operation)
    operation.addDependency(startingOperation)
    underlyingOperationQueue.addOperation(operation)
  }

  //TODO: isSuspended  / maxConcurrentOperationCount

}

extension GroupOperation: AdvancedOperationQueueDelegate {

  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {}
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {}

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidStart operation: Operation) {}
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
    guard !errors.isEmpty else { return }

    if operation !== finishingOperation || operation !== startingOperation {
      aggregatedErrors.append(contentsOf: errors)
    }
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {}

}
