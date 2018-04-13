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

final class GroupOperationTests: XCTestCase {

  func testStress1() {
    for i in 1...500 {
      print("\(i)")
      testOperationCancelled()
      testOperationCancelledAsynchronously()
    }
  }

  func testStress2() {
    for i in 1...500 {
      print("\(i)")
      testGroupOperationCancelled()
      testGroupOperationCancelledWithError()
    }
  }

  func testStress3() {
    for i in 1...500 {
      print("\(i)")
      testCancelledGroupOperationInNestedGroupOperations()
      testGroupOperationsCancelled()
    }
  }

  func testStandardFlow() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = BlockOperation(block: { sleep(1)} )
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2)
    group.addCompletionBlock { expectation3.fulfill() }
    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertTrue(group.isSuspended)

    XCTAssertTrue(group.isSuspended)
    group.start()
    XCTAssertFalse(group.isSuspended)
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isSuspended)
    XCTAssertTrue(group.isFinished)
  }

  func testOperationCancelled() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = RunUntilCancelledOperation()
    operation1.addCompletionBlock { [unowned operation1] in
      XCTAssertTrue(operation1.isCancelled, "It should be cancelled for state: \(operation1.state).")
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = BlockOperation(block: { sleep(1)} )
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2)
    group.addCompletionBlock { expectation3.fulfill() }
    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)

    XCTAssertTrue(group.isSuspended)
    group.start()
    XCTAssertFalse(group.isSuspended)
    operation1.cancel(error: MockError.test)

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isCancelled, "It should be cancelled for state: \(operation1.state).")
    XCTAssertTrue(operation1.isFinished, "It should be finished for state: \(operation1.state).")
    XCTAssertEqual(operation1.errors.count, 1)

    XCTAssertFalse(group.isCancelled, "It should be cancelled for state: \(group.state).")
    XCTAssertTrue(group.isFinished, "It should be finished for state: \(group.state).")
    XCTAssertTrue(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 1)
  }

  func testOperationCancelledAsynchronously() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = BlockOperation(block: { sleep(1)} )
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2)
    group.addCompletionBlock { expectation3.fulfill() }
    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)

    XCTAssertTrue(group.isSuspended)
    group.start()
    XCTAssertFalse(group.isSuspended)
    DispatchQueue.global().async {
      operation1.cancel(error: MockError.test)
    }

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertEqual(operation1.errors.count, 1)

    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 1)
  }

  func testBlockOperationCancelled() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledOperation()
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation3 = BlockOperation(block: { sleep(1)} )
    operation3.addCompletionBlock { expectation3.fulfill() }

    let expectation4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.addCompletionBlock { expectation4.fulfill() }

    group.start()
    operation2.cancel()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(group.isFinished)
    XCTAssertEqual(group.aggregatedErrors.count, 0)

  }

  func testGroupOperationCancelled() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = RunUntilCancelledOperation()
    operation1.addCompletionBlock {
      XCTAssertFalse(operation1.isExecuting)
      XCTAssertTrue(operation1.isCancelled, "It should be cancelled for state: \(operation1.state).")
      XCTAssertTrue(operation1.isFinished)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledOperation()
    operation2.addCompletionBlock {
      XCTAssertFalse(operation2.isExecuting)
      XCTAssertTrue(operation2.isCancelled, "It should be cancelled for state: \(operation1.state).")
      XCTAssertTrue(operation2.isFinished)
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation3 = RunUntilCancelledOperation()
    operation3.addCompletionBlock {
      XCTAssertFalse(operation3.isExecuting)
      XCTAssertTrue(operation3.isCancelled, "It should be cancelled for state: \(operation1.state).")
      XCTAssertTrue(operation3.isFinished)
      expectation3.fulfill()
    }

    let expectation4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.addCompletionBlock {
      XCTAssertFalse(group.isExecuting)
      XCTAssertTrue(group.isCancelled, "It should be cancelled for state: \(operation1.state).")
      XCTAssertTrue(group.isFinished)
      expectation4.fulfill()
    }

    group.start()
    group.cancel()

    waitForExpectations(timeout: 10)
  }

  func testGroupOperationCancelledWithError() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = RunUntilCancelledOperation()
    operation1.completionBlock = {
      XCTAssertFalse(operation1.isExecuting)
      XCTAssertTrue(operation1.isCancelled)
      XCTAssertTrue(operation1.isFinished)
      XCTAssertEqual(operation1.errors.count, 0)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledOperation()
    operation2.completionBlock = {
      XCTAssertFalse(operation2.isExecuting)
      XCTAssertTrue(operation2.isCancelled)
      XCTAssertTrue(operation2.isFinished)
      XCTAssertEqual(operation2.errors.count, 0)
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation3 = RunUntilCancelledOperation()
    operation3.completionBlock = {
      XCTAssertFalse(operation3.isExecuting)
      XCTAssertTrue(operation3.isCancelled)
      XCTAssertTrue(operation3.isFinished)
      XCTAssertEqual(operation3.errors.count, 0)
      expectation3.fulfill()
    }

    let expectation4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.completionBlock = {
      XCTAssertFalse(group.isExecuting)
      XCTAssertTrue(group.isCancelled)
      XCTAssertTrue(group.isFinished)
      XCTAssertEqual(group.errors.count, 1)
      XCTAssertEqual(group.aggregatedErrors.count, 0)
      expectation4.fulfill()
    }

    group.start()
    group.cancel(error: MockError.test)
    group.cancel(error: MockError.test)
    group.cancel(error: MockError.test)

    waitForExpectations(timeout: 10)
  }

  func testGroupOperationWithWaitUntilFinished() {
    let operation1 = BlockOperation(block: { sleep(2)} )
    let operation2 = BlockOperation(block: { sleep(2)} )
    let operation3 = BlockOperation(block: { sleep(2)} )
    let group = GroupOperation(operations: operation1, operation2, operation3)

    group.start()
    group.waitUntilFinished()

    for operation in [operation1, operation2, operation3, group] {
      XCTAssertFalse(operation.isExecuting)
      XCTAssertFalse(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
      if let advancedOperation = operation as? AdvancedOperation {
        XCTAssertEqual(advancedOperation.errors.count, 0)
      } else if let groupOperation = operation as? GroupOperation {
        XCTAssertEqual(groupOperation.aggregatedErrors.count, 0)
      }
    }
  }

  func testNestedGroupOperations() {
    let operation1 = BlockOperation(block: { } )
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = BlockOperation(block: { sleep(1) } )
    let group2 = GroupOperation(operations: operation3, operation4, operation5)

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    let group = GroupOperation(operations: group1, group2, operation6)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isFinished)
  }

  func testMultipleNestedGroupOperations() {
    let exepectation0 = expectation(description: "\(#function)\(#line)")
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    let exepectation2 = expectation(description: "\(#function)\(#line)")
    let exepectation3 = expectation(description: "\(#function)\(#line)")
    let exepectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = BlockOperation(block: { } )
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])
    group1.addCompletionBlock { exepectation1.fulfill() }

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = BlockOperation(block: { sleep(1) } )

    let operation6 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group3 = GroupOperation(operations: operation6)
    group3.addCompletionBlock { exepectation3.fulfill() }

    let group2 = GroupOperation(operations: operation3, operation4, operation5, group3)
    group2.addCompletionBlock { exepectation2.fulfill() }

    let group4 = GroupOperation(operations: [])
    group4.addCompletionBlock { exepectation4.fulfill() }

    let operation7 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)
    let group0 = GroupOperation(operations: group1, group2, operation7, group4)

    group0.addCompletionBlock { exepectation0.fulfill() }

    group0.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group0.isFinished)
  }

  func testCancelledGroupOperationInNestedGroupOperations() {
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group2 = GroupOperation(operations: operation3, operation4, operation5)

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    let group = GroupOperation(operations: group1, group2, operation6)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group2.cancel(error: MockError.test)
    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(!group.isReady)
    XCTAssertTrue(!group.isExecuting)
    XCTAssertTrue(!group.isCancelled)
    XCTAssertTrue(group.isFinished)
  }

  func testGroupOperationsCancelled() {
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group2 = GroupOperation(operations: operation3, operation4, operation5)

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    let group = GroupOperation(operations: group1, group2, operation6)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.cancel(error: MockError.test)
    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: [MockError.test])
  }

  func testFailedOperationInSimpleNestedGroupOperations() {
    let errors = [MockError.test]

    let operation1 = SleepyAsyncOperation(interval1: 3, interval2: 4, interval3: 1)
    let group1 = GroupOperation(operations: operation1)
    operation1.cancel(error: MockError.test)

    let group = GroupOperation(operations: group1)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: errors)
  }

  func testFailedOperationInNestedGroupOperations() {
    let errors = [MockError.test, MockError.failed, MockError.failed]

    let operation1 = SleepyOperation()
    let operation2 = SleepyOperation()
    let group1 = GroupOperation(operations: operation1, operation2)

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors)
    let group2 = GroupOperation(operations: operation3, operation4)

    let group = GroupOperation(operations: group1, group2)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: errors)
  }

  func testFailedAndCancelledOperationsInNestedGroupOperations() {
    let errors = [MockError.test, MockError.failed, MockError.failed]

    let operation1 = SleepyOperation()
    let operation2 = SleepyOperation()
    let group1 = GroupOperation(operations: operation1, operation2)

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors)
    let group2 = GroupOperation(operations: operation3, operation4)

    let group = GroupOperation(operations: group1, group2)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    operation3.cancel(error: MockError.failed)
    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation3.isCancelled)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertSameErrorQuantity(errors: operation3.errors, expectedErrors: [MockError.failed])

    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: [MockError.test, MockError.failed, MockError.failed, MockError.failed])
  }

  func testMultipleFailedOperationsInNestedGroupOperations() {
    let errors1 = [MockError.test, MockError.failed, MockError.failed]
    let errors2 = [MockError.test, MockError.generic(date: Date()), MockError.generic(date: Date())]

    let operation1 = FailingAsyncOperation(errors: errors1)
    let operation2 = SleepyOperation()
    let group1 = GroupOperation(operations: operation1, operation2)

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors2)
    let group2 = GroupOperation(operations: operation3, operation4)

    let group = GroupOperation(operations: group1, group2)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: errors1 + errors2)
  }

  func testMaxConcurrentOperationCount() {
    let errors = [MockError.test, MockError.failed, MockError.failed]
    let operation1 = FailingAsyncOperation(errors: errors)
    let operation2 = SleepyOperation()
    let group = GroupOperation(operations: operation1, operation2)
    let exepectation1 = expectation(description: "\(#function)\(#line)")

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    group.maxConcurrentOperationCount = 4
    XCTAssertEqual(group.maxConcurrentOperationCount, 4)
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertEqual(group.maxConcurrentOperationCount, 4)
  }

  func testComposition() {
    let expectationGroup = expectation(description: "\(#function)\(#line)")
    let expectationAdapter = expectation(description: "\(#function)\(#line)")

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let operation2 = SleepyAsyncOperation()
    operation2.addCompletionBlock { expectation2.fulfill() }
    
    let operation3 = SleepyOperation()
    operation3.addCompletionBlock { expectation3.fulfill() }

    let adapterOperation = AdvancedBlockOperation { [unowned operation2] in
      operation2.cancel()
    }
    adapterOperation.addCompletionBlock { expectationAdapter.fulfill() }

    adapterOperation.addDependency(operation1)
    operation2.addDependency(adapterOperation)
    operation3.addDependency(operation2)

    let group = GroupOperation(operations: [operation1, operation2, operation3, adapterOperation])
    group.addCompletionBlock { expectationGroup.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(adapterOperation.isFinished)
  }

  func testCompositionWithCondition() {
    let expectationGroup = expectation(description: "\(#function)\(#line)")
    let expectationAdapter = expectation(description: "\(#function)\(#line)")

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let operation2 = SleepyAsyncOperation()
    operation2.addCompletionBlock { expectation2.fulfill() }
    operation2.addCondition(NoFailedDependenciesCondition()) // this condition will set operation2 as pending

    let operation3 = SleepyOperation()
    operation3.addCompletionBlock { expectation3.fulfill() }

    let adapterOperation = AdvancedBlockOperation { [unowned operation2] in
      operation2.cancel()
    }
    adapterOperation.addCompletionBlock { expectationAdapter.fulfill() }

    adapterOperation.addDependency(operation1)
    operation2.addDependency(adapterOperation)
    operation3.addDependency(operation2)

    let group = GroupOperation(operations: [operation1, operation2, operation3, adapterOperation])
    group.addCompletionBlock { expectationGroup.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(adapterOperation.isFinished)
  }

  func testQualityOfService() {
    let operation1 = SleepyOperation()
    let group = GroupOperation(operations: operation1)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    XCTAssertEqual(group.qualityOfService, .default)
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    group.qualityOfService = .userInitiated
    waitForExpectations(timeout: 10)

    XCTAssertEqual(group.qualityOfService, .userInitiated)
  }

  func testObservers() {
    let errors = [MockError.test, MockError.failed, MockError.failed]
    let operation1 = FailingAsyncOperation(errors: errors)
    let operation2 = SleepyOperation()
    let group = GroupOperation(operations: operation1, operation2)
    let exepectation1 = expectation(description: "\(#function)\(#line)")

    let observer = MockObserver()
    group.addObserver(observer)

    group.addCompletionBlock { exepectation1.fulfill() }
    group.start()
    group.qualityOfService = .userInitiated
    waitForExpectations(timeout: 10)

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 0)
  }

}
