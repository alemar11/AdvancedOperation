//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
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

/// An `AdvancedOperation` subclass which enables a finite grouping of other operations.
/// Use a `GroupOperation` to associate related operations together, thereby creating higher levels of abstractions.
/// - Note: The progress report is designed to work with a *serial* GroupOperation: if the operations are run concurrently the progress
/// report may be less accurate (i.e. KVO could report the same percentage multipe times, except for the final value).
/// - Attention: If you add normal `Operations`, the progress report will ignore them, instead consider using only `AdvancedOperations`.
open class GroupOperation: AdvancedOperation {
  // MARK: - Properties
  
  public override var log: OSLog {
    didSet {
      underlyingOperationQueue.operations.forEach { operation in
        if let advancedOperation = operation as? AdvancedOperation,
          //advancedOperation !== startingOperation, advancedOperation !== finishingOperation,
          advancedOperation.log === OSLog.disabled {
          advancedOperation.log = log
        }
      }
    }
  }

  /// Stores all of the `AdvancedOperation` errors during the execution.
  internal let aggregatedErrors = Atomic([Error]())
  
  /// Internal `AdvancedOperationQueue`.
  private let underlyingOperationQueue: AdvancedOperationQueue

  /// Tracks all the pending/executing operations.
  /// Due to the fact the operations are removed from an OperationQueue when cancelled/finished,
  /// the OperationQueue internal count cannot be reliably used in the AdvancedOperationQueue delegates
  private let operationCount = Atomic(0)
  
  private let temporaryCancelErrors = Atomic([Error]())
  
  private let cancellationRequested = Atomic(false)
  
  // MARK: - Initialization
  
  /// Creates a `GroupOperation`instance.
  ///
  /// - Parameters:
  ///   - operations: The operations of which the `GroupOperation` is composed of.
  ///   - qualityOfService: The default service level to apply to operations executed using the queue.
  ///   - maxConcurrentOperationCount: The maximum number of queued operations that can execute at the same time.
  ///   - underlyingQueue: An optional DispatchQueue which defaults to nil, this parameter is set as the underlying queue of the group's own `AdvancedOperationQueue`.
  /// - Note: If the operation object has an explicit quality of service level set, that value is used instead.
  public convenience init(
    operations: Operation...,
    qualityOfService: QualityOfService = .default,
    maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount,
    underlyingQueue: DispatchQueue? = .none
    ) {
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

    // in a GroupOperation the totalUnitCount is equal to 1 + children's pendingUnitCount
    // that's because if the underlyingQueue is concurrent the progress completion will be determined by the "1".
    // If the underlyingQueue is serial the progress totalUnitCount is equal to the children's pendingUnitCount.
    // If the underlyingQueue is concurrent the progress totalUnitCount is equal to 1 + children's pendingUnitCount.
    // The + 1 is a way to ensure that the progress results completed only when all the conccurrent operations are finished.
    if maxConcurrentOperationCount == 1  {
      self.progress.totalUnitCount = 0
    }
    self.underlyingOperationQueue.delegate = self
    
    for operation in operations {
      addOperation(operation: operation)
    }
  }
  
  deinit {
    self.underlyingOperationQueue.delegate = nil
  }
  
  /// Advises the `GroupOperation` object that it should stop executing its tasks.
  /// - Note: Once all the tasks are cancelled, the GroupOperation state will be set as finished if it's started.
  public final override func cancel(errors: [Error]) {
   let cancellationAlreadyRequested = cancellationRequested.safeAccess { value -> Bool in
      if value {
        return false
      } else {
        value = true
        return  false
      }
    }
    
    guard !cancellationAlreadyRequested else { return }

    temporaryCancelErrors.mutate { $0 = errors }
    
    guard !isCancelled && !isFinished else {
      return
    }

    underlyingOperationQueue.cancelAllOperations()
    underlyingOperationQueue.isSuspended = false
  }
  
  open override func cancel() {
    cancel(errors: [])
  }
  
  /// Performs the receiver’s non-concurrent task.
  /// - Note: If overridden, be sure to call the parent `main` as the **end** of the new implementation.
  open override func execute() {
    // if it's cancelling, the finish command will be called automatically
    if cancellationRequested.value && !isCancelled {
      return
    }
    
    if isCancelled {
      finish()
      return
    }

    if operationCount.value == 0 {
      finish()
      return
    }
    
    underlyingOperationQueue.isSuspended = false
  }
  
  /// Add an operation.
  ///
  /// - Parameters:
  ///   - operation: The operation to add.
  ///   - weight: The `AdvancedOperation` weight for the progress report (it defaults to 1).
  ///   - Atention: The progress report ignores normal `Operations`, instead consider using only `AdvancedOperations`.
  public func addOperation(operation: Operation, withProgressWeight weight: Int64 = 1) {
    assert(!isExecuting, "The GroupOperation is executing and cannot accept more operations.")
    assert(!isCancelled || !isFinished, "The GroupOperation is finishing and cannot accept more operations.")

    if let advancedOperation = operation as? AdvancedOperation {

      // "The value for pending unit count is the amount of the parent’s totalUnitCount consumed by the child."
      //
      progress.totalUnitCount += weight
      progress.addChild(advancedOperation.progress, withPendingUnitCount: weight)
      if advancedOperation.log === OSLog.disabled {
        advancedOperation.log = log
      }
    }
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
  
  /// This property specifies the service level applied to operation objects added to the `GroupOperation`. (It defaults to the `default` quality.)
  /// If the operation object has an explicit service level set, that value is used instead.
  public final override var qualityOfService: QualityOfService {
    get {
      return underlyingOperationQueue.qualityOfService
    }
    set {
      underlyingOperationQueue.qualityOfService = newValue
    }
  }
}

extension GroupOperation: AdvancedOperationQueueDelegate {
  public func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    operationCount.mutate{ $0 += 1 }
  }
  
  public func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) { }
  
  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: AdvancedOperation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else {
      return
    }

    if !errors.isEmpty { // avoid TSAN _swiftEmptyArrayStorage
      aggregatedErrors.mutate { $0.append(contentsOf: errors) }
    }
  }
  
  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
    guard operationQueue === underlyingOperationQueue else {
      return
    }

    assert(operationCount.value > 0, "The operation count should be greater than 0.")
    operationCount.mutate{ $0 -= 1 }

    if operationCount.value == 0 {
      if cancellationRequested.value {
        super.cancel(errors: temporaryCancelErrors.value)
        
        /// An operation that is not yet started cannot be finished
        if isExecuting {
          /// Waiting for the cancellation process to complete
          /// It's a refinement to avoid some cases where a cancelled GroupOperation moves
          /// to its finished state before having its cancelled state fulfilled.
          while !isCancelled { }
          
          underlyingOperationQueue.isSuspended = true
          finish()
        }
      } else {
        underlyingOperationQueue.isSuspended = true
        finish(errors: self.aggregatedErrors.value)
      }
    }
  }
  
  public func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: AdvancedOperation, withErrors errors: [Error]) { }
  
  public func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: AdvancedOperation, withErrors errors: [Error]) { }
}
