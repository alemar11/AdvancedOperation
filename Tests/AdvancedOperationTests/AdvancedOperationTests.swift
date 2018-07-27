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

final class AdvancedOperationTests: XCTestCase {

  //  func testStress() {
  //    for i in 1...100 {
  //      print(i)
  //      //testStart()
  //      //testMultipleCancel()
  //      testMultipleStartsAndCancels()
  //    }
  //  }

  func testStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.start()
    operation.start()
    operation.start()

    XCTAssertTrue(operation.isExecuting)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleAsyncStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let queue = DispatchQueue(label: "test")
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)


    queue.async {
      operation.start()
    }
    operation.start()
    queue.async {
      operation.start()
    }
    XCTAssertTrue(operation.isExecuting)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancelBeforeStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.cancel()
    operation.start()
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    operation.cancel()
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleCancelWithManyObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    for _ in 1...100 {
      operation.addObserver(BlockObserver())
    }

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    let queue = DispatchQueue(label: "test")

    operation.cancel()

    queue.async {
      operation.cancel(error: MockError.test)
    }
    operation.cancel(error: MockError.failed)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleStartsAndCancels() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)
    operation.start()
    XCTAssertTrue(operation.isExecuting)

    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    operation.start()
    XCTAssertFalse(operation.isExecuting, "Should not executing for state: \(operation.state)")
    XCTAssertTrue(operation.isCancelled, "Should be cancelled for state: \(operation.state)")

    // Those errors will be ignored since the operation is already cancelled
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)

    XCTAssertFalse(operation.isExecuting)
    XCTAssertTrue(operation.isCancelled)

    XCTAssertFalse(operation.isExecuting)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)

  }

  func testMultipleStartAndCancelWithErrors() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    operation.cancel(error: MockError.test)
    operation.start()
    XCTAssertFalse(operation.isExecuting)
    operation.cancel()
    operation.cancel(error: MockError.failed)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [MockError.test])
  }

  func testMultipleCancelWithError() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    let error = MockError.cancelled(date: Date())
    operation.cancel(error: error)
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [error])
  }

  func testBailingOutEarly() {
    let operation = SleepyAsyncOperation()

    XCTAssertTrue(operation.isReady)

    operation.cancel()
    operation.start()

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)

    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    operation.waitUntilFinished()
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let observer = MockObserver()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer)

    operation.completionBlock = { expectation1.fulfill() }

    operation.start()
    operation.start()
    waitForExpectations(timeout: 10)

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.willFinishCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willCancelCount, 0)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testObserversWithCancelCommand() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let observer = MockObserver()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer)

    operation.completionBlock = { expectation1.fulfill() }

    operation.start()
    operation.cancel()
    operation.cancel(error: MockError.cancelled(date: Date()))

    waitForExpectations(timeout: 10)

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.willFinishCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willCancelCount, 1)
    XCTAssertEqual(observer.didCancelCount, 1)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testObserversWithOperationProduction() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let observer = MockObserver()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer)

    operation.completionBlock = { expectation1.fulfill() }
    operation.produceOperation(BlockOperation { })
    operation.produceOperation(BlockOperation { })
    operation.start()

    waitForExpectations(timeout: 10)

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didProduceCount, 2)
    XCTAssertEqual(observer.willFinishCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willCancelCount, 0)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testCancelWithErrors() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()

    operation.completionBlock = { expectation1.fulfill() }
    operation.start()

    XCTAssertTrue(operation.isExecuting)

    operation.cancel(error: MockError.test)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [MockError.test])
  }

  func testFinishWithErrors() {
    let operation = FailingAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()

    waitForExpectations(timeout: 10)
    XCTAssertEqual(operation.errors.count, 2)
  }

  // The readiness of operations is determined by their dependencies on other operations and potentially by custom conditions that you define.
  func testReadiness() {
    // Given
    let operation1 = SleepyAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation1.addCompletionBlock { expectation1.fulfill() }
    XCTAssertTrue(operation1.isReady)

    let operation2 = BlockOperation(block: {} )
    let expectation2 = expectation(description: "\(#function)\(#line)")
    operation2.addExecutionBlock { expectation2.fulfill() }

    // When
    operation1.addDependency(operation2)
    XCTAssertFalse(operation1.isReady)

    // Then
    operation2.start()
    XCTAssertTrue(operation1.isReady)
    operation1.start()
    waitForExpectations(timeout: 5)
    XCTAssertFalse(operation1.isReady) // its state is finished
  }

  func testSubclassableObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    let expectation6 = expectation(description: "\(#function)\(#line)")

    let operation1 = SelfObservigOperation()
    let operation2 = AdvancedBlockOperation { }
    let error = MockError.test

    operation1.willExecuteHandler = {
      expectation1.fulfill()
    }

    operation1.didProduceOperationHandler = { operation in
      XCTAssertTrue(operation2 === operation)
      expectation2.fulfill()
    }

    operation1.willCancelHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation3.fulfill()
    }

    operation1.didCancelHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation4.fulfill()
    }

    operation1.willFinishHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation5.fulfill()
    }

    operation1.didFinishHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation6.fulfill()
    }

    operation1.start()
    operation1.produceOperation(operation2)
    operation1.cancel(error: error)
    waitForExpectations(timeout: 10)
  }

}
