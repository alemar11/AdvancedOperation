//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
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

  func testAddBlockAsOperation() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    let willAddExpectation = expectation(description: "\(#function)\(#line)")
    let willExecuteExpectation = expectation(description: "\(#function)\(#line)")
    let didAddExpectation = expectation(description: "\(#function)\(#line)")
    let didFinishExpectation = expectation(description: "\(#function)\(#line)")
    willExecuteExpectation.isInverted = true

    queue.delegate = delegate

    delegate.willAddOperationHandler = { _,_ in willAddExpectation.fulfill() }
    delegate.willExecuteOperationHandler = { _,_ in willExecuteExpectation.fulfill() }
    delegate.didAddOperationHandler = { _,_ in didAddExpectation.fulfill() }
    delegate.didFinishOperationHandler = { _,_, errors in
      XCTAssertTrue(errors.isEmpty)
      didFinishExpectation.fulfill()
    }

    queue.addOperation { }

    waitForExpectations(timeout: 2, handler: nil)
  }

  func testQueueDelegateWithAdvancedOperationsUsingWaitUntilFinished() {
    let queue = AdvancedOperationQueue()
    let delegate = MockOperationQueueDelegate()

    queue.delegate = delegate

    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 1)
    let operation2 = AdvancedBlockOperation { complete in
      complete([])
    }
    let operation3 = SleepyOperation()
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
      switch (operation) {
      case operation1: willExecuteExpectation1.fulfill()
      case operation2: willExecuteExpectation2.fulfill()
      case operation3: willExecuteExpectation3.fulfill()
      case operation4: willExecuteExpectation4.fulfill()
      default: XCTFail("Too many executions.")
      }
    }

    let willFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willFinishExpectation1.fulfill()
      case operation2: willFinishExpectation2.fulfill()
      case operation3: willFinishExpectation3.fulfill()
      case operation4: willFinishExpectation4.fulfill()
      default: XCTFail("Too many finishing operations.")
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

    delegate.willCancelOperationHandler = { (queue, operation, errors) in
      XCTFail("There should'nt be any cancelling operations.")
    }

    delegate.didCancelOperationHandler = { (queue, operation, errors) in
      XCTFail("There should'nt be any cancelled operations.")
    }

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    XCTAssertTrue(queue.operations.isEmpty)
    // at this point all the operations should be completed BUT the didFinish could not yet be called.
    waitForExpectations(timeout: 3)
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

    let willFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willFinishExpectation1.fulfill()
      case operation2: willFinishExpectation2.fulfill()
      case operation3: willFinishExpectation3.fulfill()
      case operation4: willFinishExpectation4.fulfill()
      default: XCTFail("Too many finishing operations.")
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
    queue.isSuspended = true // https://api.travis-ci.org/v3/job/447679744/log.txt

    let operation1 = SleepyOperation(interval: 0)
    let operation2 = BlockOperation { }
    let operation3 = DelayOperation(interval: 0)
    let operation4 = DelayOperation(interval: 0)

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

    let willFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willFinishExpectation1.fulfill()
      case operation2: XCTFail("a BlockOperation doesn't have this callback.")
      case operation3: willFinishExpectation3.fulfill()
      case operation4: willFinishExpectation4.fulfill()
      default: XCTFail("Undefined finishing operations.")
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

    queue.isSuspended = false
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
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

    let willFinishExpectation1 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation2 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation3 = expectation(description: "\(#function)\(#line)")
    let willFinishExpectation4 = expectation(description: "\(#function)\(#line)")

    delegate.willFinishOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: willFinishExpectation1.fulfill()
      case operation2: willFinishExpectation2.fulfill()
      case operation3: willFinishExpectation3.fulfill()
      case operation4: willFinishExpectation4.fulfill()
      default: XCTFail("Undefined finishing operations.")
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

    let willCancelExpectation1 = expectation(description: "\(#function)\(#line)")
    let willCancelExpectation2 = expectation(description: "\(#function)\(#line)")
    delegate.willCancelOperationHandler = { (queue, operation, errors) in
      XCTAssertTrue(queue == queue)
      switch (operation) {
      case operation1: XCTFail("This operation shouldn't be cancelling.")
      case operation2: willCancelExpectation1.fulfill()
      case operation3: XCTFail("This operation shouldn't be cancelling.")
      case operation4: willCancelExpectation2.fulfill()
      default: XCTFail("Undefined cancelled operations.")
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

  func testFailIfAtLeastOnDependencyHasBeenCancelled() {
    let queue = AdvancedOperationQueue()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 3, interval2: 3, interval3: 3)
    let operation5 = SleepyOperation()
    let operation6 = SleepyOperation()
    [operation6, operation5, operation4, operation3, operation2].then(operation1)

    let conditionOperation = AdvancedBlockOperation { [unowned operation1] in
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

  func testMemoryLeakFailIfAtLeastOnDependencyHasBeenCancelled() {
    var queue: AdvancedOperationQueue? = AdvancedOperationQueue()
    weak var weakQueue = queue

    let expectation1 = expectation(description: "\(#function)\(#line)")
    var operation1: AdvancedOperation? = SleepyOperation()
    weak var weakOperation1 = operation1

    autoreleasepool {
      let operation2 = SleepyAsyncOperation()
      let operation3 = SleepyOperation()
      let operation4 = SleepyAsyncOperation(interval1: 3, interval2: 3, interval3: 3)
      let operation5 = SleepyOperation()
      let operation6 = SleepyOperation()
      [operation6, operation5, operation4, operation3, operation2].then(operation1!)

      let conditionOperation = AdvancedBlockOperation { [weak operation1] in
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

      queue!.addOperations([operation1!, operation2, operation3, operation4, operation5, operation6, conditionOperation], waitUntilFinished: false)
      operation4.cancel()
      waitForExpectations(timeout: 10)
      XCTAssertTrue(operation1!.isCancelled)

      queue = nil
      operation1 = nil

      sleep(2)
    }

    XCTAssertNil(weakQueue, "The queue should be nilled out.")
    XCTAssertNil(weakOperation1, "operation1 should be nilled out.")
  }

  func testMemoryLeakFailOnceOperationsHaveBeenCompleted() {
    let queue: AdvancedOperationQueue? = AdvancedOperationQueue()

    var operation1: AdvancedOperation? = SleepyAsyncOperation()
    operation1!.name = "operation1"
    var operation2: AdvancedOperation? = SleepyOperation()
    operation2!.name = "operation2"
    var operation3: AdvancedOperation? = SleepyAsyncOperation(interval1: 1, interval2: 2, interval3: 1)
    operation3!.name = "operation3"
    var operation4: AdvancedOperation? = SleepyOperation()
    operation4!.name = "operation4"

    weak var weakOperation1 = operation1
    weak var weakOperation2 = operation2
    weak var weakOperation3 = operation3
    weak var weakOperation4 = operation4

    XCTAssertNotNil(weakOperation1)
    XCTAssertNotNil(weakOperation2)
    XCTAssertNotNil(weakOperation3)
    XCTAssertNotNil(weakOperation4)

    autoreleasepool {
      queue!.addOperations([operation1!, operation2!, operation3!, operation4!], waitUntilFinished: true)

      sleep(2) // It appears that the queue needs some time to "remove" the operations.

      operation1 = nil
      operation2 = nil
      operation3 = nil
      operation4 = nil
    }

    // All the operations should have been deallocated by now.
    XCTAssertNil(weakOperation1, "Leak: operation1 should be nilled out. The queue has still \(queue!.operations.count) operations.")
    XCTAssertNil(weakOperation2, "Leak: operation2 should be nilled out. The queue has still \(queue!.operations.count) operations.")
    XCTAssertNil(weakOperation3, "Leak: operation3 should be nilled out. The queue has still \(queue!.operations.count) operations.")
    XCTAssertNil(weakOperation4, "Leak: operation4 should be nilled out. The queue has still \(queue!.operations.count) operations.")
  }

  func testProducedOperation() {
    let producedOperation = SleepyAsyncOperation()
    let producer = ProducingOperationsOperation.OperationProducer(producedOperation, true, 0)
    let producingOperation = ProducingOperationsOperation(operationProducers: [producer])
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: producedOperation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: producingOperation, expectedValue: true)
    let queue = AdvancedOperationQueue()
    queue.addOperation(producingOperation)

    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertFalse(producingOperation.isCancelled)
    XCTAssertFalse(producedOperation.isCancelled)
  }

  func testSynchronousOperationFinishedWithoutErrors() {
    let operation = SynchronousOperation(errors: [])
    let queue = AdvancedOperationQueue()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)

    queue.addOperation(operation)

    wait(for: [expectation1], timeout: 10)
  }

  func testSynchronousOperationFinishedWithErrors() {
    let operation = SynchronousOperation(errors: [MockError.failed, MockError.test])
    let queue = AdvancedOperationQueue()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)

    wait(for: [expectation1], timeout: 10)

    XCTAssertTrue(operation.hasErrors)
  }

  func testAccessingOperationQueueFromOperation() {
    let queue = AdvancedOperationQueue()
    let operation = OperationReferencingOperationQueue(queue: queue)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)

    wait(for: [expectation1], timeout: 10)
  }

  // this test check if a subclass of Operation gets executed even if it is cancelled
  func testInvesticationStandardOperationInsideAnAdvacedOperationQueue() {
    let queue = AdvancedOperationQueue()

    let operation = SimpleOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isCancelled), object: operation, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isExecuting), object: operation, expectedValue: true)
    expectation3.isInverted = true
    queue.isSuspended = true
    queue.addOperation(operation)
    operation.cancel()
    XCTAssertFalse(operation.isFinished)
    queue.isSuspended = false
    self.wait(for: [expectation1, expectation2], timeout: 3)
  }

}
