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

/// An `AsynchronousOperation` subclass which enables a finite grouping of other operations.
/// Use a `GroupOperation` to associate related operations together, thereby creating higher levels of abstractions.
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
      super.qualityOfService = newValue
      operationQueue.qualityOfService = newValue
    }
  }
  
  // MARK: - Private Properties

  private let dispatchGroup = DispatchGroup()
  private let dispatchQueue = DispatchQueue(label: "\(identifier).GroupOperation.serialQueue")
  private var tokens = [NSKeyValueObservation]()
  private lazy var operationQueue: OperationQueue = {
    $0.isSuspended = true
    return $0
  }(OperationQueue())

  // MARK: - Initializers
  
  public convenience init(underlyingQueue: DispatchQueue? = nil, operations: Operation...) {
    self.init(underlyingQueue: underlyingQueue, operations: operations)
  }
  
  public init(underlyingQueue: DispatchQueue? = nil, operations: [Operation]) {
    super.init()
    self.operationQueue.underlyingQueue = underlyingQueue
    operations.forEach { addOperation($0) }
  }
  
  deinit {
    tokens.forEach { $0.invalidate() }
    tokens.removeAll()
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

    dispatchGroup.notify(queue: dispatchQueue) {
      self.finish()
    }
    operationQueue.isSuspended = false
  }
  
  open override func cancel() {
    dispatchQueue.sync {
      super.cancel()
      operationQueue.cancelAllOperations()
    }
  }
  
  /// Adds a new `operation` to the `GroupOperation`.
  ///
  /// - Note: If the `GroupOperation` is already cancelled,  the new  operation will be cancelled before being added.
  public final func addOperation(_ operation: Operation) {
    dispatchQueue.sync {
      assert(!isFinished, "Operations can only be added if the GroupOperation has not yet finished.")
      guard !isFinished else { return }

      // If the GroupOperation is cancelled, operations will be cancelled before being added to the queue.
      if isCancelled {
        operation.cancel()
      }

      dispatchGroup.enter()
      let finishToken = operation.observe(\.isFinished, options: [.old, .new]) { [weak self] (_, changes) in
        guard let self = self else { return }
        guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
        guard newValue else { return }

        self.dispatchGroup.leave()
      }

      tokens.append(finishToken)

      operationQueue.addOperation(operation)
    }
  }
}
