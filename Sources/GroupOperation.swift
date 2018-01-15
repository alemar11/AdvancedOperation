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
  
  public let underlyingOperationQueue = AdvancedOperationQueue()
  
  private lazy var startingOperation = BlockOperation(block: {
    print("\n\n----------------- START")
  })

  
  private(set) var aggregateErrors = [Error]()

  private lazy var finishingOperation: BlockOperation = {
    return BlockOperation { [weak self] in
      guard let `self` = self else { return }
      self.finish(errors: self.aggregateErrors)
      print("\n\n----------------- END")
    }
  }()
  
  
  convenience init(operations: Operation...) {
    self.init(operations: operations)
  }
  
  init(operations: [Operation]) {
    super.init()
    underlyingOperationQueue.isSuspended = true
    underlyingOperationQueue.delegate = self
    underlyingOperationQueue.addOperation(startingOperation)
    
    for operation in operations {
      finishingOperation.addDependency(operation)
      operation.addDependency(startingOperation)
      underlyingOperationQueue.addOperation(operation)
    }
    
  }
  
  override final func cancel() {
    // cancels all the operations except the internal finishing one.
    //TODO: add startingOperation? in the if block?
    for operation in underlyingOperationQueue.operations {
      if (operation !== finishingOperation) {
        operation.cancel()
      }
    }
    super.cancel()
  }
  
  //  override final func cancel(error: Error? = nil) {
  ////    if let error = error {
  ////      errors.append(error)
  ////    }
  ////    cancel()
  //
  //    // cancels all the operations except the internal finishing one.
  //    for operation in underlyingOperationQueue.operations {
  //      if (operation !== finishingOperation) {
  //        operation.cancel()
  //      }
  //    }
  //    super.cancel(error: error)
  //
  //  }
  
  
  
  override final func main() {
    underlyingOperationQueue.isSuspended = false
    underlyingOperationQueue.addOperation(finishingOperation)
  }
  
  //TODO: test
//  func addOperation(operation: Operation) {
//    finishingOperation.addDependency(operation)
//    underlyingOperationQueue.addOperation(operation)
//  }
  
  /// `suspended` equal to false in order to start any added group operations.
  //  public var isSuspended: Bool {
  //    get {
  //      return underlyingQueue.isSuspended
  //    }
  //    set(newIsSuspended) {
  //      underlyingQueue.isSuspended = newIsSuspended
  //    }
  //  }
  
  /// Accesses the group operation queue's quality of service. It defaults to background quality.
  public final override var qualityOfService: QualityOfService {
    //TODO: kvo?
    get {
      return _qualityOfService
    }
    set(newQualityOfService) {
      _qualityOfService = newQualityOfService
      underlyingOperationQueue.qualityOfService = _qualityOfService
    }
  }
  
  private var _qualityOfService = QualityOfService.default {
    willSet {
      willChangeValue(forKey: #keyPath(Operation.qualityOfService))
    }
    didSet {
      didChangeValue(forKey: #keyPath(Operation.qualityOfService))
    }
  }
  
  //TODO: isSuspended  / maxConcurrentOperationCount
  
}

extension GroupOperation: AdvancedOperationQueueDelegate {
  
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    //    if operation !== finishingOperation { // avoid deadlock
    //      finishingOperation.addDependency(operation)
    //    }
    //
    //    if operation !== startingOperation {
    //      operation.addDependency(startingOperation)
    //    }
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {}
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillPerform operation: Operation) {
    print("an operation will perform: \(type(of: operation))")
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidPerform operation: Operation, withErrors errors: [Error]) {
    // --> these callback works well only with AdvancedOperationQueue
    if operation === finishingOperation {
      //TODO:
      // it seems that sometimes the finish is called before all the other operations callbacks
      // possible solution: create an AdvancedBlockOperation to use here for the start and finish blocks
      // we will call finish ONLY when the current operation == finishOperation
    } else if operation == startingOperation {
      
    //} else if operation is AdvancedOperation {
    } else {
      aggregateErrors.append(contentsOf: errors)
      print("an operation has finished: \(type(of: operation)) with: \(aggregateErrors.count) aggregate errors and \(errors.count) errors")
    }
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) {
    print("operationWillCancel: \(type(of: operation))")
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {
    print("operationDidCancel: \(type(of: operation))")
  }
  
}
