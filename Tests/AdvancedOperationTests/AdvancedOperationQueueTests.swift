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

final class AdvancedOperationQueueTests: XCTestCase {

  func testQueueWithAdvancedOperationsUsingWaitUntilFinished() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate

    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = DelayOperation(interval: 1)

    let willAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willAddExpectation1.fulfill()
      case operation2: willAddExpectation2.fulfill()
      case operation3: willAddExpectation3.fulfill()
      case operation4: willAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let didAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didAddExpectation1.fulfill()
      case operation2: didAddExpectation2.fulfill()
      case operation3: didAddExpectation3.fulfill()
      case operation4: didAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let willExecuteExpectation1 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation2 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation3 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willExecuteOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willExecuteExpectation1.fulfill()
      case operation2: willExecuteExpectation2.fulfill()
      case operation3: willExecuteExpectation3.fulfill()
      case operation4: willExecuteExpectation4.fulfill()
      default: XCTFail("Too many executions.")
      }
    }

    let didFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didFinishExpectation1.fulfill()
      case operation2: didFinishExpectation2.fulfill()
      case operation3: didFinishExpectation3.fulfill()
      case operation4: didFinishExpectation4.fulfill()
      default: XCTFail("Too many finished operations.")
      }
    }

    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      XCTFail("There should'nt be any cancelled operations.")
    }

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    waitForExpectations(timeout: 0) // at this point all the operations should be completed
  }

  func testQueueWithAdvancedOperationsWithoutUsingWaitUntilFinished() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate
    queue.isSuspended = true

    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = DelayOperation(interval: 1)

    let willAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willAddExpectation1.fulfill()
      case operation2: willAddExpectation2.fulfill()
      case operation3: willAddExpectation3.fulfill()
      case operation4: willAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let didAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didAddExpectation1.fulfill()
      case operation2: didAddExpectation2.fulfill()
      case operation3: didAddExpectation3.fulfill()
      case operation4: didAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let willExecuteExpectation1 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation2 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation3 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willExecuteOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willExecuteExpectation1.fulfill()
      case operation2: willExecuteExpectation2.fulfill()
      case operation3: willExecuteExpectation3.fulfill()
      case operation4: willExecuteExpectation4.fulfill()
      default: XCTFail("Too many executions.")
      }
    }

    let didFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didFinishExpectation1.fulfill()
      case operation2: didFinishExpectation2.fulfill()
      case operation3: didFinishExpectation3.fulfill()
      case operation4: didFinishExpectation4.fulfill()
      default: XCTFail("Undefined finished operations.")
      }
    }

    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      XCTFail("There should'nt be any cancelled operations.")
    }

    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)
    queue.isSuspended = false

    waitForExpectations(timeout: 10)
  }

  func testQueueWithMixedOperations() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate
    queue.isSuspended = true

    let operation1 = SleepyOperation()
    let operation2 = BlockOperation(block: { print(#function) })
    let operation3 = DelayOperation(interval: 2)
    let operation4 = DelayOperation(interval: 1)

    let willAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willAddExpectation1.fulfill()
      case operation2: willAddExpectation2.fulfill()
      case operation3: willAddExpectation3.fulfill()
      case operation4: willAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let didAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didAddExpectation1.fulfill()
      case operation2: didAddExpectation2.fulfill()
      case operation3: didAddExpectation3.fulfill()
      case operation4: didAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let willExecuteExpectation1 = expectation(description: "\(#function)\(#line)")
    //let willExecuteExpectation2 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation3 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willExecuteOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willExecuteExpectation1.fulfill()
      case operation2: XCTFail("a BlockOperation doesn't have this callback.")
      case operation3: willExecuteExpectation3.fulfill()
      case operation4: willExecuteExpectation4.fulfill()
      default: XCTFail("Too many executions.")
      }
    }

    let didFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didFinishExpectation1.fulfill()
      case operation2: didFinishExpectation2.fulfill()
      case operation3: didFinishExpectation3.fulfill()
      case operation4: didFinishExpectation4.fulfill()
      default: XCTFail("Undefined finished operations.")
      }
    }

    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      XCTFail("There should'nt be any cancelled operations.")
    }

    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)
    queue.isSuspended = false

    waitForExpectations(timeout: 10)
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

    let willAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let willAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willAddExpectation1.fulfill()
      case operation2: willAddExpectation2.fulfill()
      case operation3: willAddExpectation3.fulfill()
      case operation4: willAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let didAddExpectation1 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation2 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation3 = expectation(description: "\(#function)\(#line)")
    let didAddExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didAddOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didAddExpectation1.fulfill()
      case operation2: didAddExpectation2.fulfill()
      case operation3: didAddExpectation3.fulfill()
      case operation4: didAddExpectation4.fulfill()
      default: XCTFail("Added too many operations.")
      }
    }

    let willExecuteExpectation1 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation2 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation3 = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willExecuteOperationHandler = { (queue, operation) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1:
        willExecuteExpectation1.fulfill()
      case operation2:
        operation.cancel()
        willExecuteExpectation2.fulfill()
      case operation3:
        willExecuteExpectation3.fulfill()
      case operation4:
        operation.cancel()
        willExecuteExpectation4.fulfill()
      default: XCTFail("Too many executions.")
      }
    }

    let didFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.didFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: didFinishExpectation1.fulfill()
      case operation2: didFinishExpectation2.fulfill()
      case operation3: didFinishExpectation3.fulfill()
      case operation4: didFinishExpectation4.fulfill()
      default: XCTFail("Undefined finished operations.")
      }
    }

    let didCancelExpectation1 = expectation(description: "\(#function)\(#line)")
    let didCancelExpectation2 = expectation(description: "\(#function)\(#line)")
    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: XCTFail("This operation shouldn't be cancelled.")
      case operation2: didCancelExpectation1.fulfill()
      case operation3: XCTFail("This operation shouldn't be cancelled.")
      case operation4: didCancelExpectation2.fulfill()
      default: XCTFail("Undefined cancelled operations.")
      }
    }

    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)
    queue.isSuspended = false

    waitForExpectations(timeout: 10)
  }

  func testFailIfAtLeastOnDependecyHasBeenCancelled() {
    let queue = AdvancedOperationQueue()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 3, interval2: 3, interval3: 3)
    let operation5 = SleepyOperation()
    let operation6 = SleepyOperation()
    [operation6, operation5, operation4, operation3, operation2].then(operation1)

    let conditionOperation = BlockOperation { [unowned operation1] in
      XCTAssertEqual(operation1.dependencies.count, 6)
      let cancelled = operation1.dependencies.filter { $0.isCancelled }
      if !cancelled.isEmpty {
        operation1.cancel()
      }
    }
    XCTAssertEqual(operation1.dependencies.count, 5)
    for dependency in operation1.dependencies {
      dependency.then(conditionOperation)
    }

    conditionOperation.then(operation1)
    operation1.addCompletionBlock {
      expectation1.fulfill()
    }

    queue.addOperations([operation1, operation2, operation3, operation4, operation5, operation6, conditionOperation], waitUntilFinished: false)
    operation4.cancel()
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation1.isCancelled)

  }


  func testMemoryLeakFailIfAtLeastOnDependecyHasBeenCancelled() {
    let queue = AdvancedOperationQueue()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    var operation1: AdvancedOperation? = SleepyOperation()
    weak var weakOperation1 = operation1

    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 3, interval2: 3, interval3: 3)
    let operation5 = SleepyOperation()
    let operation6 = SleepyOperation()
    [operation6, operation5, operation4, operation3, operation2].then(operation1!)

    let conditionOperation = BlockOperation { [weak operation1] in
      guard let operation1 = operation1 else { return }
      let cancelled = operation1.dependencies.filter { $0.isCancelled }
      if !cancelled.isEmpty {
        operation1.cancel()
      }
    }

    for dependency in operation1!.dependencies {
      dependency.then(conditionOperation)
    }

    conditionOperation.then(operation1!)
    operation1!.addCompletionBlock {
      expectation1.fulfill()
    }

    queue.addOperations([operation1!, operation2, operation3, operation4, operation5, operation6, conditionOperation], waitUntilFinished: false)
    operation4.cancel()
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation1!.isCancelled)

    operation1 = nil
    XCTAssertNil(weakOperation1)
  }
}
