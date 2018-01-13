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

import XCTest
@testable import AdvancedOperation

class AdvancedOperationQueueTests: XCTestCase {
  
  func testQueueWithAdvancedOperations() {
    let queue = AdvancedOperationQueue()
    let delegate = QueueDelegate()
    
    queue.delegate = delegate
    
    /*
     queue.isSuspended = true
     print(queue.isSuspended)
     */
    
    let operationOne = SleepyAsyncOperation()
    let operationTwo = SleepyAsyncOperation()
    let operationThree = SleepyAsyncOperation()
    let operationFour = DelayOperation(interval: 1)
    
    var addCount = 0
    delegate.addOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch addCount {
      case 0:
        XCTAssertTrue(operation == operationOne)
      case 1:
        XCTAssertTrue(operation == operationTwo)
      case 2:
        XCTAssertTrue(operation == operationThree)
      case 3:
        XCTAssertTrue(operation == operationFour)
      default:
        XCTFail("Added too many operations.")
      }
      addCount += 1
    }
    
    var startCount = 0
    delegate.startOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      startCount += 1
    }
    
    var finishCount = 0
    delegate.finishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      finishCount += 1
    }
    
    var cancelCount = 0
    delegate.cancelOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      cancelCount += 1
    }
    
    //queue.addOperations([operationOne, operationTwo, operationThree, operationFour], waitUntilFinished: true)
    
    /*
     queue.addOperation(operationOne)
     queue.addOperation(operationTwo)
     queue.addOperation(operationThree)
     queue.addOperation(operationFour)
     queue.isSuspended = false
     //this setup needs an expectation
     */
    
    XCTAssertEqual(addCount, 4)
    XCTAssertEqual(startCount, 4)
    XCTAssertEqual(finishCount, 4)
    XCTAssertEqual(cancelCount, 0)
    
  }
  
}
