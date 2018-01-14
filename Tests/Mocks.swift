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
@testable import AdvancedOperation

internal class SleepyAsyncOperation: AdvancedOperation {
  
  override func main() {
    DispatchQueue.global().async { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else { return self.finish() }
      
      if strongSelf.isCancelled { strongSelf.finish() }
      sleep(2)
      if strongSelf.isCancelled { strongSelf.finish() }
      sleep(3)
      
      strongSelf.finish()
    }
    
  }
  
}

internal class SleepyOperation: AdvancedOperation {
  enum Error: Swift.Error { case test }
  
  override func main() {
    sleep(1)
    self.finish(errors: [Error.test])
  }
}

internal class QueueDelegate: AdvancedOperationQueueDelegate {
  
  //TODO: renaming all the handlers
  
  var addOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var startOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var cancelOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  var finishOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    self.addOperationHandler?(operationQueue, operation)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillPerform operation: Operation) {
    self.startOperationHandler?(operationQueue, operation)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidPerform operation: Operation, withErrors errors: [Error]) {
    self.finishOperationHandler?(operationQueue, operation, errors)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) {
    
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {
    self.cancelOperationHandler?(operationQueue, operation, errors)
  }
}
