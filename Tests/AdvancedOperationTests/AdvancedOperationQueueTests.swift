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

extension AdvancedOperationQueueTests {

  static var allTests = [
    ("testQueueWithAdvancedOperations", testQueueWithAdvancedOperations),
    ("testQueueWithAdvancedOperations2", testQueueWithAdvancedOperations2)
  ]

}

class AdvancedOperationQueueTests: XCTestCase {

  func testQueueWithAdvancedOperations() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate

    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = DelayOperation(interval: 1)
    let lock = NSLock()
    let syncQueue = DispatchQueue.init(label: "org.tinrobots.advanced-operation.sync")

    var addCount = 0
    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch addCount {
      case 0:
        XCTAssertTrue(operation == operation1)
      case 1:
        XCTAssertTrue(operation == operation2)
      case 2:
        XCTAssertTrue(operation == operation3)
      case 3:
        XCTAssertTrue(operation == operation4)
      default:
        XCTFail("Added too many operations: \(addCount).")
      }
      addCount += 1
    }

    var startCount = 0
    delegate.willPerformOperationHandler = { (queue, operation) in
      //lock.lock()
      syncQueue.sync {
        startCount += 1
        XCTAssertTrue(queue == queue)
      }
      //lock.unlock()
    }

    var finishCount = 0
    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      //lock.lock()
      syncQueue.sync {
      finishCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      }
      //lock.unlock()
    }

    var cancelCount = 0
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      //lock.lock()
      syncQueue.sync {
      cancelCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      }
      //lock.unlock()
    }

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)

    XCTAssertEqual(addCount, 4)
    XCTAssertEqual(startCount, 4)
    XCTAssertEqual(finishCount, 4)
    XCTAssertEqual(cancelCount, 0)
  }

  //TODO: most of the callbacks can only be activated by subclassed of AdvancedOperation
  //TODO: rename
  func testQueueWithAdvancedOperations2() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate
    queue.isSuspended = true

    let operation1 = SleepyOperation()
    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    let operation3 = DelayOperation(interval: 2)
    let operation4 = DelayOperation(interval: 1)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    var addCount = 0
    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch addCount {
      case 0:
        XCTAssertTrue(operation == operation1)
      case 1:
        XCTAssertTrue(operation == operation2)
      case 2:
        XCTAssertTrue(operation == operation3)
      case 3:
        XCTAssertTrue(operation == operation4)
      default:
        XCTFail("Added too many operations.")
      }
      addCount += 1
    }

    let lock = NSLock()

    var startCount = 0
    delegate.willPerformOperationHandler = { (queue, operation) in
      lock.lock()
      startCount += 1
      XCTAssertTrue(queue == queue)
      lock.unlock()
    }

    var finishCount = 0
    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      lock.lock()
      finishCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)

      if operation === operation1 {
        expectation1.fulfill()
      } else if operation === operation2 {
        expectation2.fulfill()
      } else if operation === operation3 {
        expectation3.fulfill()
      } else if operation === operation4 {
        expectation4.fulfill()
      } else {
        XCTFail("Undefined operation")
      }
      lock.unlock()
    }

    var cancelCount = 0
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      lock.lock()
      cancelCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      lock.unlock()
    }

    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)
    queue.isSuspended = false

    waitForExpectations(timeout: 10)

    XCTAssertEqual(addCount, 4)
    XCTAssertEqual(startCount, 4)
    XCTAssertEqual(finishCount, 4)
    XCTAssertEqual(cancelCount, 0)
  }

}
