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

final class StateObservableOperationTests: XCTestCase {
  func testObserveExecutionStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = FailingOperation()

    operation.state.observe(.executing) { op in
      if op.isExecuting {
        XCTAssertFalse(op.isFinished)
        expectation1.fulfill()
      } else {
        XCTAssertTrue(op.isFinished)
        expectation2.fulfill()
      }
    }
    operation.start()

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testObserveExecutionAndFinishStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = FailingOperation()

    operation.state.observe(.cancelled) { _ in
      XCTFail("This operation hasn't been cancelled.")
    }
    operation.state.observe(.executing) { op in
      if op.isExecuting {
        XCTAssertFalse(op.isFinished)
        expectation1.fulfill()
      }
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      XCTAssertTrue(op.isFailed)
      expectation2.fulfill()
    }

    operation.start()

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testNestedObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.expectedFulfillmentCount = 2
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation = RunUntilCancelledAsyncOperation()

    operation.state.observe(.executing) { op in
      guard op.isExecuting else { return }
      expectation1.fulfill()
    }

    operation.state.observe(.executing) { op in
      guard op.isExecuting else { return }

      expectation1.fulfill()
      op.state.observe(.cancelled) { op in
        expectation2.fulfill()
        op.state.observe(.finished) { op in
          expectation3.fulfill()
        }
      }
      op.cancel()
    }

    operation.start()
    wait(for: [expectation1, expectation2, expectation3], timeout: 5)
  }

  func testObserveStartAndFinishStatesWhenRunningOnQueue() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation1.expectedFulfillmentCount = 2
    expectation2.expectedFulfillmentCount = 3
    let operation = BlockOperation()
    let queue = OperationQueue()

    operation.state.observe(.cancelled) { _ in
      XCTFail("This operation hasn't been cancelled.")
    }
    operation.state.observe(.executing) { op in
      guard op.isExecuting else { return }
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.state.observe(.executing) { op in
      guard op.isExecuting else { return }
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    queue.addOperation(operation)

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testObserveCancelAndFinishStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()

    operation.state.observe(.cancelled) { _ in
      expectation1.fulfill()
    }
    operation.state.observe(.executing) { op in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    operation.cancel()
    operation.start()

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testObserveCancelAndFinishStatesWhenRunningOnQueue() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = BlockOperation()
    let queue = OperationQueue()

    operation.state.observe(.cancelled) { _ in
      expectation1.fulfill()
    }
    operation.state.observe(.executing) { op in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.state.observe(.finished) { op in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }

    operation.cancel()
    queue.addOperation(operation)

    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testReadiness() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation1 = BlockOperation()
    let operation2 = BlockOperation()
    let queue = OperationQueue()

    operation2.state.observe(.ready) { op in
      if op.isReady { // once the operation1 depedency has been finished
        expectation1.fulfill()
      } else { // setting operation1 as dependecy
        expectation2.fulfill()
      }
    }

    operation2.addDependency(operation1)
    queue.addOperations([operation1, operation2], waitUntilFinished: false)
    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testMemoryLeak() {
    var operation: BlockOperation? = BlockOperation()
    weak var weakOperation: Operation? = operation

    operation!.state.observe(.executing) { _ in }
    operation!.state.observe(.executing) { _ in }

    weak var weakObserver = operation!.state
    operation = nil
    XCTAssertNil(weakOperation)
    XCTAssertNil(weakObserver)
  }
}
