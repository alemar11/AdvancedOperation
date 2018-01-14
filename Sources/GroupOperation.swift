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

class GroupOperation: AdvancedOperation {
  
  public let underlyingQueue = AdvancedOperationQueue()
  
  private lazy var startingOperation = BlockOperation(block: {})
  private lazy var finishingOperation: BlockOperation = {
    let operation = BlockOperation { [weak self] in
      guard let `self` = self else { return }
      self.finish()
    }
    return operation
  }()

  
  convenience init(operations: Operation...) {
    self.init(operations: operations)
  }
  
  init(operations: [Operation]) {
    super.init()
    underlyingQueue.isSuspended = true
    underlyingQueue.delegate = self
    underlyingQueue.addOperation(startingOperation)
    
    for operation in operations {
      underlyingQueue.addOperation(operation)
    }
  }
  
  override final func cancel() {
    underlyingQueue.cancelAllOperations()
    super.cancel()
  }
  
  override final func main() {
    underlyingQueue.isSuspended = false
    underlyingQueue.addOperation(finishingOperation)
  }
  
  func addOperation(operation: Operation) {
    underlyingQueue.addOperation(operation)
  }
  
  /// `suspended` equal to false in order to start any added group operations.
//  public var isSuspended: Bool {
//    get {
//      return underlyingQueue.isSuspended
//    }
//    set(newIsSuspended) {
//      underlyingQueue.isSuspended = newIsSuspended
//    }
//  }
  
  /// Accesses the group operation queue's quality of service. It defaults to
  /// background quality.
  public override var qualityOfService: QualityOfService {
    //TODO: kvo?
    get {
      return underlyingQueue.qualityOfService
    }
    set(newUnderlyingQualityOfService) {
      underlyingQueue.qualityOfService = newUnderlyingQualityOfService
    }
  }
  
  
  /// Waits until all the group's operations are finished.
  ///
  /// Does *not* automatically resume the group's operation queue. Waiting for
  /// the group operations makes no sense when the queue is suspended. The
  /// operation will wait forever unless empty. Empty queues will not wait
  /// because all its operations have finished, because there are none
  /// remaining.
//  public func waitUntilAllOperationsAreFinished() {
//    underlyingQueue.waitUntilAllOperationsAreFinished()
//  }
  
}

extension GroupOperation: AdvancedOperationQueueDelegate {
  
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    if operation !== finishingOperation { // avoid deadlock
      finishingOperation.addDependency(operation)
    }
    
    if operation !== startingOperation {
      operation.addDependency(startingOperation)
    }
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {
    
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillPerform operation: Operation) {
    
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidPerform operation: Operation, withErrors errors: [Error]) {
    
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) {
    
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {
    
  }
  
}
