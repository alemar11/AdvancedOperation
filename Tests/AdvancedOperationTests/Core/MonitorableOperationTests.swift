//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

final class MonitorableOperationTests: XCTestCase {
  func testMonitorStartAndFinishStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = FailingOperation()

    if #available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, OSXApplicationExtension 10.15, *) {
      operation.someMonitor.addCancelBlock { _ in
        XCTFail("This operation hasn't been cancelled.")
      }
      operation.someMonitor.addStartExecutionBlock { op in
        XCTAssertTrue(op.isExecuting)
        XCTAssertFalse(op.isFinished)
        expectation1.fulfill()
      }
      operation.someMonitor.addFinishBlock { op in
        XCTAssertFalse(op.isExecuting)
        XCTAssertTrue(op.isFinished)
        let failingOp = op as! FailingOperation
        XCTAssertTrue(failingOp.isFailed)
        expectation2.fulfill()
      }
    } else {
      operation.monitor.addCancelBlock { _ in
        XCTFail("This operation hasn't been cancelled.")
      }
      operation.monitor.addStartExecutionBlock { op in
        XCTAssertTrue(op.isExecuting)
        XCTAssertFalse(op.isFinished)
        expectation1.fulfill()
      }
      operation.monitor.addFinishBlock { op in
        XCTAssertFalse(op.isExecuting)
        XCTAssertTrue(op.isFinished)
        XCTAssertTrue(op.isFailed)
        expectation2.fulfill()
      }
    }

    operation.start()

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testMonitorStartAndFinishStatesWhenRunningOnQueue() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation1.expectedFulfillmentCount = 2
    expectation2.expectedFulfillmentCount = 3
    let operation = BlockOperation()
    let queue = OperationQueue()

    operation.monitor.addCancelBlock { _ in
      XCTFail("This operation hasn't been cancelled.")
    }
    operation.monitor.addStartExecutionBlock { op in
      XCTAssertTrue(op.isExecuting)
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.monitor.addStartExecutionBlock { op in
      XCTAssertTrue(op.isExecuting)
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.monitor.addFinishBlock { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.monitor.addFinishBlock { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.monitor.addFinishBlock { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    queue.addOperation(operation)

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testMonitorCancelAndFinishStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()

    operation.monitor.addCancelBlock { _ in
      expectation1.fulfill()
    }
    operation.monitor.addStartExecutionBlock { op in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.monitor.addFinishBlock { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    operation.cancel()
    operation.start()

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testMonitorCancelAndFinishStatesWhenRunningOnQueue() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = BlockOperation()
    let queue = OperationQueue()

    operation.monitor.addCancelBlock { _ in
      expectation1.fulfill()
    }
    operation.monitor.addStartExecutionBlock { op in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.monitor.addFinishBlock { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    operation.cancel()
    queue.addOperation(operation)

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testMemoryLeak() {
    var operation: BlockOperation? = BlockOperation()
    weak var weakOperation: Operation? = operation

    operation!.monitor.addStartExecutionBlock { _ in }
    operation!.monitor.addStartExecutionBlock { _ in }

    weak var weakMonitor = operation!.monitor
    operation = nil
    XCTAssertNil(weakOperation)
    XCTAssertNil(weakMonitor)
  }
}
