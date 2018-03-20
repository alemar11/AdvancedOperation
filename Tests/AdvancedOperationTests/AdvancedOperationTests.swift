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

class AdvancedOperationTests: XCTestCase {

  func testStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    waitForExpectations(timeout: 10)
    XCTAssertOperationFinished(operation: operation)
  }

  func testMultipleStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    operation.start()
    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    waitForExpectations(timeout: 10)
    XCTAssertOperationFinished(operation: operation)
  }

  func testCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    operation.cancel()
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation)
  }

  func testMultipleCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    operation.cancel()
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation)
  }

  func testMultipleStartAndCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    operation.start()
    XCTAssertTrue(operation.isCancelled)

    // Those errors will be ignored since the operation is already cancelled
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)

    XCTAssertFalse(operation.isExecuting)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation)
  }

  func testMultipleStartAndCancelWithErrors() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    operation.cancel(error: MockError.test)
    operation.start()
    XCTAssertFalse(operation.isExecuting)
    operation.cancel()
    operation.cancel(error: MockError.failed)
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation, errors: [MockError.test])
  }

  func testMultipleCancelWithError() {
    let expectation1 = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.start()
    XCTAssertOperationExecuting(operation: operation)

    let error = MockError.cancelled(date: Date())
    operation.cancel(error: error)
    operation.cancel(error: MockError.test)
    operation.cancel(error: MockError.failed)
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation, errors: [error])
  }

  func testBailingOutEarly() {
    let operation = SleepyAsyncOperation()

    XCTAssertOperationCanBeStarted(operation: operation)

    operation.cancel()
    operation.start()
    XCTAssertOperationCancelled(operation: operation)

    operation.cancel()
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    operation.waitUntilFinished()
    XCTAssertOperationCancelled(operation: operation)
  }

  func testObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let observer = MockObserver()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer: observer)

    operation.completionBlock = { expectation1.fulfill() }

    operation.start()
    operation.start()
    waitForExpectations(timeout: 10)

    sleep(5) // make sure there are no other effects

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testObserversWithCancelCommand() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let observer = MockObserver()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer: observer)

    operation.completionBlock = { expectation1.fulfill() }

    operation.start()
    operation.cancel()
    operation.cancel(error: MockError.cancelled(date: Date()))
    waitForExpectations(timeout: 10)

    sleep(5) // make sure there are no other effects

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 1)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testCancelWithErrors() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()

    operation.completionBlock = { expectation1.fulfill() }
    operation.start()

    XCTAssertOperationExecuting(operation: operation)

    operation.cancel(error: MockError.test)
    XCTAssertDefaultReadiness(operation: operation)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    XCTAssertOperationCancelled(operation: operation, errors: [MockError.test])
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

  // MARK: - Conditions

  func testEvaluatingConditionsState() {
    class DemoCondition: OperationCondition {
      var name = "DemoCondition"
      var isMutuallyExclusive = false
      func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
        DispatchQueue.global().async {
          sleep(3)
          completion(OperationConditionResult.satisfied)
        }
      }
    }

    let operation1 = SleepyAsyncOperation()
    operation1.addCondition(condition: DemoCondition())

    XCTAssertTrue(operation1.isReady)
    XCTAssertEqual(operation1.state, .ready)

    operation1.willEnqueue()
    XCTAssertFalse(operation1.isReady)
    XCTAssertEqual(operation1.state, .evaluatingConditions)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isReady), object: operation1, expectedValue: true)

    wait(for: [expectation1], timeout: 5)
    XCTAssertEqual(operation1.state, .ready)
    XCTAssertTrue(operation1.isReady)
  }

}
