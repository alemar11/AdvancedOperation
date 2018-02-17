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
    ("testQueueWithAdvancedOperationsUsingWaitUntilFinished", testQueueWithAdvancedOperationsUsingWaitUntilFinished),
    ("testQueueWithAdvancedOperationsUsingWaitForExpectations", testQueueWithAdvancedOperationsUsingWaitForExpectations)
  ]

}

class AdvancedOperationQueueTests: XCTestCase {

// FIXME: timeout with waitUntilFinished on Travis CI

  func testQueueWithAdvancedOperationsUsingWaitUntilFinished() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate

    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = DelayOperation(interval: 1)
    let lock = NSLock()

    var willAddCount = 0
    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch willAddCount {
      case 0:
        XCTAssertTrue(operation == operation1)
      case 1:
        XCTAssertTrue(operation == operation2)
      case 2:
        XCTAssertTrue(operation == operation3)
      case 3:
        XCTAssertTrue(operation == operation4)
      default:
        XCTFail("Added too many operations: \(willAddCount).")
      }
      willAddCount += 1
    }

    var didAddCount = 0
    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch didAddCount {
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
      didAddCount += 1
    }

    var willExecuteCount = 0
    delegate.willExecuteOperationHandler = { (queue, operation) in
      lock.lock()
      willExecuteCount += 1
      XCTAssertTrue(queue == queue)
      lock.unlock()
    }

    var didFinishCount = 0
    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didFinishCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      lock.unlock()
    }

    var didCancelCount = 0
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didCancelCount += 1
      XCTAssertTrue(queue == queue)
      XCTAssertEqual(errors.count, 0)
      lock.unlock()
    }

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)

    XCTAssertEqual(willAddCount, 4)
    XCTAssertEqual(didAddCount, 4)
    XCTAssertEqual(willExecuteCount, 4)
    XCTAssertEqual(didFinishCount, 4)
    XCTAssertEqual(didCancelCount, 0)
  }

  func testQueueWithAdvancedOperationsUsingWaitForExpectations() {
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

    var willAddCount = 0
    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch willAddCount {
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
      willAddCount += 1
    }

    var didAddCount = 0
    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch didAddCount {
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
      didAddCount += 1
    }

    let lock = NSLock()

    var willExecuteCount = 0
    delegate.willExecuteOperationHandler = { (queue, operation) in
      lock.lock()
      willExecuteCount += 1
      XCTAssertTrue(queue == queue)
      lock.unlock()
    }

    var didFinishCount = 0
    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didFinishCount += 1
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

    var didCancelCount = 0
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didCancelCount += 1
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

    XCTAssertEqual(willAddCount, 4)
    XCTAssertEqual(didAddCount, 4)
    XCTAssertEqual(willExecuteCount, 4)
    XCTAssertEqual(didFinishCount, 4)
    XCTAssertEqual(didCancelCount, 0)
  }

  // Most of the callbacks can only be activated by subclassed of AdvancedOperation
  func testQueueWithMixedOperations() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate
    queue.isSuspended = true

    let operation1 = SleepyOperation()
    let operation2 = BlockOperation(block: { print(#function) })
    let operation3 = DelayOperation(interval: 2)
    let operation4 = DelayOperation(interval: 1)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    var willAddCount = 0
    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch willAddCount {
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
      willAddCount += 1
    }

    var didAddCount = 0
    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch didAddCount {
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
      didAddCount += 1
    }

    let lock = NSLock()

    var willExecuteCount = 0
    delegate.willExecuteOperationHandler = { (queue, operation) in
      lock.lock()
      willExecuteCount += 1
      XCTAssertTrue(queue == queue)
      lock.unlock()
    }

    var didFinishCount = 0
    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didFinishCount += 1
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

    var didCancelCount = 0
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      lock.lock()
      didCancelCount += 1
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

    XCTAssertEqual(willAddCount, 4)
    XCTAssertEqual(didAddCount, 4)
    XCTAssertEqual(willExecuteCount, 3) // The BlockOperation cannot be observed for this state
    XCTAssertEqual(didFinishCount, 4)
    XCTAssertEqual(didCancelCount, 0)
  }

    func testQueueWithCancel() {
      let queue = AdvancedOperationQueue()
      let delegate = MockOperationQueueDelegate()

      queue.delegate = delegate
      queue.isSuspended = true

      let operation1 = SleepyOperation()
      let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
      let operation3 = SleepyOperation()
      let operation4 = SleepyOperation()

      let expectation1 = expectation(description: "\(#function)\(#line)")
      let expectation2 = expectation(description: "\(#function)\(#line)")
      let expectation3 = expectation(description: "\(#function)\(#line)")
      let expectation4 = expectation(description: "\(#function)\(#line)")

      var willAddCount = 0
      delegate.willAddOperationHandler = { (queue, operation) in
        XCTAssertTrue(queue == queue)
        switch willAddCount {
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
        willAddCount += 1
      }

      var didAddCount = 0
      delegate.didAddOperationHandler = { (queue, operation) in
        XCTAssertTrue(queue == queue)
        switch didAddCount {
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
        didAddCount += 1
      }

      let lock = NSLock()

      var willExecuteCount = 0
      delegate.willExecuteOperationHandler = { (queue, operation) in
        lock.lock()
        willExecuteCount += 1
        XCTAssertTrue(queue == queue)
        lock.unlock()
        if willExecuteCount%2 == 0 {
          //sleep(2)
          operation.cancel()
        }
      }

      var didFinishCount = 0
      delegate.didFinishOperationHandler = { (queue, operation, errors) in
        lock.lock()
        didFinishCount += 1
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

      var didCancelCount = 0
      delegate.didCancelOperationHandler = { (queue, operation, errors) in
        lock.lock()
        didCancelCount += 1
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

      XCTAssertEqual(willAddCount, 4)
      XCTAssertEqual(didAddCount, 4)
      XCTAssertEqual(willExecuteCount, 4)
      XCTAssertEqual(didFinishCount, 4)
      XCTAssertEqual(didCancelCount, 2)
}
}
