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

final class ObservableOperationTests: XCTestCase {
  func testObserveExecutionStates() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = FailingOperation()

    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { (op, change) in
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

    operation.kvo.observe(\.isCancelled, options: [.old, .new]) { (op, change) in
      XCTFail("This operation hasn't been cancelled.")
    }
    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      if op.isExecuting {
        XCTAssertFalse(op.isFinished)
        expectation1.fulfill()
      }
    }
    operation.kvo.observe(\.isFinished, options: [.old, .new]) { (op, change) in
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

    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      guard op.isExecuting else { return }
      expectation1.fulfill()
    }

    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      guard op.isExecuting else { return }

      expectation1.fulfill()
      op.kvo.observe(\.isCancelled, options: [.old, .new]) { (op, change) in
        expectation2.fulfill()
        op.kvo.observe(\.isFinished, options: [.old, .new]) { (op, change) in
          XCTAssertFalse(op.isExecuting)
          expectation3.fulfill()
        }
      }
      // op.finish() This will cause a crash (deadlock) but it shouldn't be called anyway
      op.cancel()
    }

    operation.start()
    wait(for: [expectation1, expectation2, expectation3], timeout: 5)
  }

  func testNestedObservers2() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = InfiniteAsyncOperation()

    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      guard op.isExecuting else { return }
      expectation1.fulfill()

      op.kvo.observe(\.isFinished, options: [.old, .new]) { (op, change) in
        expectation2.fulfill()
      }
      op.stop()
    }

    operation.start()
    wait(for: [expectation1, expectation2], timeout: 5)
  }

  func testObserveStartAndFinishStatesWhenRunningOnQueue() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation1.expectedFulfillmentCount = 2
    expectation2.expectedFulfillmentCount = 3
    let operation = BlockOperation()
    let queue = OperationQueue()

    operation.kvo.observe(\.isCancelled, options: [.old, .new]) { (op, change) in
      XCTFail("This operation hasn't been cancelled.")
    }
    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      guard op.isExecuting else { return }
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, change in
      guard let newValue = change.newValue, newValue else { return }
      XCTAssertFalse(op.isFinished)
      expectation1.fulfill()
    }
    operation.kvo.observe(\.isFinished, options: [.old, .new]) { op, _ in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.kvo.observe(\.isFinished, options: [.old, .new]) { op, _ in
      XCTAssertFalse(op.isExecuting)
      XCTAssertTrue(op.isFinished)
      expectation2.fulfill()
    }
    operation.kvo.observe(\.isFinished, options: [.old, .new]) { op, _ in
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

    operation.kvo.observe(\.isCancelled, options: [.old, .new]) { (op, change) in
      expectation1.fulfill()
    }
    operation.kvo.observe(\.isExecuting) { op in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.kvo.observe(\.isFinished) { op in
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

    operation.kvo.observe(\.isCancelled, options: [.old, .new]) { op, change in
      expectation1.fulfill()
    }
    operation.kvo.observe(\.isExecuting, options: [.old, .new]) { op, _ in
      XCTFail("This operation shouldn't execute its task.")
    }
    operation.kvo.observe(\.isFinished, options: [.old, .new]) { op, change in
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

    operation2.kvo.observe(\.isReady, options: [.old, .new]) { op, change in
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

  func testOtherKVOCompliantsProperties() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    expectation1.expectedFulfillmentCount = 3
    let expectation2 = expectation(description: "\(#function)\(#line)")
    expectation2.expectedFulfillmentCount = 3
    let expectation3 = expectation(description: "\(#function)\(#line)")
    expectation3.expectedFulfillmentCount = 2
    let operation = SleepyAsyncOperation()
    let dep1 = BlockOperation()
    let dep2 = BlockOperation()

    operation.kvo.observe(\.isReady, options: [.old, .new]) { (op, changes) in
      expectation1.fulfill()
    }
    operation.kvo.observe(\.dependencies, options: [.old, .new]) { (op, changes) in
      // NOTE: it seems that this obsever works only if we start observing the isReady property first (FB7586936)
      expectation2.fulfill()
    }
    operation.kvo.observe(\.queuePriority, options: [.old, .new]) { (op, changes) in
      // NOTE: it seems that changes doesn't contains any values (FB7642042)
      XCTAssertNil(changes.oldValue)
      XCTAssertNil(changes.newValue)
      expectation3.fulfill()
    }

    operation.queuePriority = .high // "default" -> high
    operation.queuePriority = .high // it doesn't trigger any KVO changes
    operation.queuePriority = .low  // high -> low

    operation.addDependency(dep1) // ready: true -> false; dependencies: nil -> [dep1]
    operation.addDependency(dep1) // ready: false -> false; dependencies: [dep1] -> [dep1]
    operation.addDependency(dep2) // ready: false -> false; dependencies: [dep1] -> [dep1, dep2]

    wait(for: [expectation1, expectation2, expectation3], timeout: 5)
  }

  func testMemoryLeak() {
    var operation: BlockOperation? = BlockOperation()
    weak var weakOperation: Operation? = operation

    operation!.kvo.observe(\.isExecuting, options: [.old, .new]) { _, _ in }
    operation!.kvo.observe(\.isExecuting) { _ in }

    weak var weakObserver = operation!.kvo
    operation = nil
    XCTAssertNil(weakOperation)
    XCTAssertNil(weakObserver)
  }
}
