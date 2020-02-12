//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

open class GroupOperation: AsynchronousOperation {
  // MARK: - Public Properties

  /// The maximum number of queued operations that can execute at the same time inside the `GroupOperation`.
  ///
  /// The value in this property affects only the operations that the current GroupOperation has executing at the same time.
  /// Reducing the number of concurrent operations does not affect any operations that are currently executing.
  public var maxConcurrentOperationCount: Int {
    get {
      return operationQueue.maxConcurrentOperationCount
    }
    set {
      operationQueue.maxConcurrentOperationCount = newValue
    }
  }

  /// The relative amount of importance for granting system resources to the operation.
  public override var qualityOfService: QualityOfService {
    get {
      return operationQueue.qualityOfService
    }
    set {
      operationQueue.qualityOfService = newValue
      // startingOperation.qualityOfService = newValue
      // finishingOperation.qualityOfService = newValue
    }
  }

  // MARK: - Private Properties

  private lazy var operationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.isSuspended = true
    return queue
  }()

  private lazy var startingOperation: BlockOperation = {
    let operation = BlockOperation()
    operation.name = "StartingOperation<\(self.operationName)>"
    return operation
  }()

  private lazy var finishingOperation: BlockOperation = {
    let operation = BlockOperation()
    operation.name = "FinishingOperation<\(self.operationName)>"
    operation.completionBlock = { [weak self] in self?.finish() }
    return operation
  }()

  public convenience init(operations: Operation...) {
    self.init(operations: operations)
  }

  public init(operations: [Operation]) {
    super.init()
    operationQueue.addOperation(startingOperation)

    operations.forEach { setupOperation($0) }
  }

  public final func addOperations(_ operations: Operation...) {
    operations.forEach { addOperation($0) }
  }

  public final func addOperation(_ operation: Operation) {
    precondition(!isFinished || !isCancelled, "Operations can only be added if the group operation has not yet finished/canceled.")
    precondition(!finishingOperation.isExecuting || !finishingOperation.isFinished || !finishingOperation.isCancelled, "Operations can't be added while the GroupOperation is finishing.")

    setupOperation(operation)
  }

  // MARK: - Public Methods

  ///  The default implementation of this method executes the scheduled operations.
  ///  If you override this method to perform the desired task,  invoke super in your implementation as last statement.
  ///  This method will automatically execute within an autorelease pool provided by Operation, so you do not need to create your own autorelease pool block in your implementation.
  public final override func main() {
    guard !isCancelled else {
      self.finish()
      return
    }

    operationQueue.addOperation(finishingOperation)
    operationQueue.isSuspended = false
  }

  open override func cancel() {
    operationQueue.cancelAllOperations()
    super.cancel()
  }

  // MARK: - Private Methods

  private func setupOperation(_ operation: Operation) {
    operation.addDependency(startingOperation)
    finishingOperation.addDependency(operation)
    operationQueue.addOperation(operation)
  }
}
