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

internal enum MockError: Swift.Error {
  case test
  case failed
}

internal class SleepyAsyncOperation: AdvancedOperation {

  private let interval1: UInt32
  private let interval2: UInt32
  private let interval3: UInt32
  
  init(interval1: UInt32 = 1, interval2: UInt32 = 2, interval3: UInt32 = 1) {
    self.interval1 = interval1
    self.interval2 = interval2
    self.interval3 = interval3
    super.init()
  }

  override func main() {
    DispatchQueue.global().async { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else { return self.finish() }
      if strongSelf.isCancelled { return strongSelf.finish() }
      
      sleep(self.interval1)
      if strongSelf.isCancelled { return strongSelf.finish() }
      
      sleep(self.interval2)
      if strongSelf.isCancelled { return strongSelf.finish()}
      
      sleep(self.interval3)
      strongSelf.finish()
    }
    
  }
  
}

internal class SleepyOperation: AdvancedOperation {
  
  override func main() {
    sleep(1)
    self.finish()
  }
}

internal class FailingOperation: AdvancedOperation {
  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
      self.finish(errors: [MockError.failed, MockError.test])
    }
  }
}

internal class QueueDelegate: AdvancedOperationQueueDelegate {
  
  var willAddOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var willPerformOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var didCancelOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  var didPerformOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    self.willAddOperationHandler?(operationQueue, operation)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {}
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillPerform operation: Operation) {
    self.willPerformOperationHandler?(operationQueue, operation)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidPerform operation: Operation, withErrors errors: [Error]) {
    self.didPerformOperationHandler?(operationQueue, operation, errors)
  }
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: Operation, withErrors errors: [Error]) {}
  
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {
    self.didCancelOperationHandler?(operationQueue, operation, errors)
  }

}
