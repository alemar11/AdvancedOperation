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

/// Operation

/**
 The NSOperation class is key-value coding (KVC) and key-value observing (KVO) compliant for several of its properties. As needed, you can observe these properties to control other parts of your application. To observe the properties, use the following key paths:
 isCancelled - read-only
 isAsynchronous - read-only
 isExecuting - read-only
 isFinished - read-only
 isReady - read-only
 dependencies - read-only
 queuePriority - readable and writable
 completionBlock - readable and writable
 **/

class OperationKeyValueObserver: NSObject {
  let operation: Operation
  
  private var _external = [OperationObserving]()
  private var observers = [NSKeyValueObservation]()
  
  init(operation: Operation) {
    self.operation = operation
    super.init()
    
    self.setup()
  }
  
  // https://www.objc.io/issues/7-foundation/key-value-coding-and-observing/
  
  private func setup() {
    let cancel = observe(\.operation.isCancelled, options: [.prior, .old, .new]) { [weak self] (operation, change) in
      
      guard let `self` = self else { return }
      
      if change.isPrior {
        guard let old = change.oldValue, old == true else { return }
        for observer in self._external {
          //willCancel
        }
        //will
      } else {
        guard let old = change.oldValue, let new = change.newValue, old == true, new == false else { return }
        for observer in self._external {
          //observer.operationDidCancel(operation: self.operation, withErrors: [])
        }
      }
      
      
    }
    
    observers.append(contentsOf: [cancel])
  }
  
}

/*
 private lazy var stateObservers: [NSKeyValueObservation] = {
 //TODO: add the prior value and check if it's different from new
 
 let cancelObserver = observe(\.isCancelled, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let cancelled = change.newValue else { return }
 
 if cancelled {
 for observer in self.observers {
 observer.operationDidCancel(operation: self, errors: self.errors)
 }
 }
 }
 
 let executeObserver = observe(\.isExecuting, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let executed = change.newValue else { return }
 
 if executed {
 for observer in self.observers {
 observer.operationDidStart(operation: self)
 }
 }
 }
 
 let finishObserver = observe(\.isFinished, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let finished = change.newValue else { return }
 
 if finished {
 for observer in self.observers {
 observer.operationDidFinish(operation: self, errors: self.errors)
 }
 }
 }
 
 return [cancelObserver, executeObserver, finishObserver]
 }()
 */


/// OperationQueue

/**
 The NSOperationQueue class is key-value coding (KVC) and key-value observing (KVO) compliant. You can observe these properties as desired to control other parts of your application. To observe the properties, use the following key paths::
 operations - read-only
 operationCount - read-only
 maxConcurrentOperationCount - readable and writable
 suspended - readable and writable
 name - readable and writable
 **/
