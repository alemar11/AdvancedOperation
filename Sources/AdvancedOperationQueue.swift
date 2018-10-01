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

public protocol AdvancedOperationQueueDelegate: class {
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation)
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation)
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: Operation)
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error])
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error])
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: Operation, withErrors errors: [Error])
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error])
}

public extension AdvancedOperationQueueDelegate {
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {}
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: Operation) {}
}

/// `AdvancedOperationQueue` is an `OperationQueue` subclass that implements a large number of "extra features" related to the `Operation` class.
open class AdvancedOperationQueue: OperationQueue {
  
  public weak var delegate: AdvancedOperationQueueDelegate?
  
  private let exclusivityManager: ExclusivityManager
  
  private let lock = NSRecursiveLock()
  
  public init(exclusivityManager: ExclusivityManager = .sharedInstance) {
    self.exclusivityManager = exclusivityManager
  }
  
  // swiftlint:disable:next cyclomatic_complexity
  open override func addOperation (_ operation: Operation) {
    lock.synchronized {
      if let operation = operation as? AdvancedOperation { /// AdvancedOperation
        
        let observer = BlockObserver(
          willExecute: { [weak self] (operation) in
            guard let self = self else { return }
            
            self.delegate?.operationQueue(operationQueue: self, operationWillExecute: operation)
            
          }, didProduce: { [weak self] in
            guard let self = self else { return }
            
            self.addOperation($1)
            
          }, willCancel: { [weak self] (operation, errors) in
            guard let self = self else { return }
            
            self.delegate?.operationQueue(operationQueue: self, operationWillCancel: operation, withErrors: errors)
            
          }, didCancel: { [weak self] (operation, errors) in
            guard let self = self else { return }
            
            self.delegate?.operationQueue(operationQueue: self, operationDidCancel: operation, withErrors: errors)
            
          }, willFinish: { [weak self] (operation, errors) in
            guard let self = self else { return }
            
            self.delegate?.operationQueue(operationQueue: self, operationWillFinish: operation, withErrors: errors)
            
          }, didFinish: { [weak self] (operation, errors) in
            guard let self = self else { return }
            
            self.delegate?.operationQueue(operationQueue: self, operationDidFinish: operation, withErrors: errors)
          }
        )
        
        operation.addObserver(observer)
        
        // Conditions
        if !operation.conditions.isEmpty {
          
          let dependencies = operation.conditions.compactMap { $0.dependency(for: operation) }
          for dependency in dependencies {
            self.addOperation(dependency)
            operation.addDependency(dependency)
          }
          
          let mutuallyExclusiveConditions = operation.conditions.filter { $0.mutuallyExclusivityMode != .disabled }
          if !mutuallyExclusiveConditions.isEmpty {
            for condition in mutuallyExclusiveConditions {
              let category = condition.name
              let cancellable = condition.mutuallyExclusivityMode == .cancel
              exclusivityManager.addOperation(operation, category: category, cancellable: cancellable)
            }
          }
          
          operation.willEnqueue()
        }
        
      } else { /// Operation
        
        // For regular `Operation`s, we'll manually call out to the queue's delegate we don't want
        // to just capture "operation" because that would lead to the operation strongly referencing itself and that's the pure definition of a memory leak.
        operation.addCompletionBlock(asEndingBlock: false) { [weak self, weak operation] in
          guard let queue = self, let operation = operation else { return }
          
          queue.delegate?.operationQueue(operationQueue: queue, operationDidFinish: operation, withErrors: [])
        }
      }
      
      delegate?.operationQueue(operationQueue: self, willAddOperation: operation)
      super.addOperation(operation)
      delegate?.operationQueue(operationQueue: self, didAddOperation: operation)
    }
  }
  
  open override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
    
    for operation in operations {
      addOperation(operation)
    }
    
    if wait {
      // waitUntilAllOperationsAreFinished()
      for operation in operations {
        operation.waitUntilFinished()
      }
    }
  }
  
}
