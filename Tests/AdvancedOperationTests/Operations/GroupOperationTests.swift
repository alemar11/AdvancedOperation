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

final class GroupOperationTests: XCTestCase {

  func testStart() {
    let operation1 = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)

    let operation2 = BlockOperation(block: { sleep(1)} )
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)

    let group = GroupOperation(operations: operation1, operation2)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertFalse(group.isSuspended)
    XCTAssertEqual(group.progress.totalUnitCount, 2)

    group.start()

    wait(for: [expectation1, expectation2, expectation3], timeout: 10)

    XCTAssertFalse(group.isSuspended)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(group.progress.isFinished)
  }

  func testCancel() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = AdvancedBlockOperation { complete in
      sleep(1)
      complete([])
    }

    let group = GroupOperation(operations: operation1, operation2)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isCancelled), object: group, expectedValue: true)

    operation1.name = "operation1"
    operation2.name = "operation2"
    group.name = "group"

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertFalse(group.isSuspended)

    group.cancel()

    wait(for: [expectation1], timeout: 10)

    /// These operations are finished because the queue they are running into is cancelled and suspended
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)

    XCTAssertTrue(group.isCancelled)
    XCTAssertFalse(group.isFinished) /// an operation that is not yet started or that is executing can't be finished (in this case we are in the first situation)
  }

  func testStartAfterCancel() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = AdvancedBlockOperation { complete in
      sleep(1)
      complete([])
    }

    let group = GroupOperation(operations: operation1, operation2)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isCancelled), object: group, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isFinished), object: group, expectedValue: true)

    operation1.name = "operation1"
    operation2.name = "operation2"
    group.name = "group"

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertFalse(group.isSuspended)

    group.cancel()
    group.start()

    wait(for: [expectation1, expectation2], timeout: 10)

    /// These operations are finished because the queue they are running into is cancelled and suspended
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertFalse(group.isSuspended)
    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(group.progress.isFinished)
  }

  func testOperationCancelled() {
    let operation1 = RunUntilCancelledAsyncOperation()
    let operation2 = BlockOperation { }
    let group = GroupOperation(operations: operation1, operation2)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertFalse(group.isSuspended)

    group.start()
    operation1.cancel(errors: [MockError.test])

    wait(for: [expectation1, expectation2, expectation3], timeout: 10)

    XCTAssertTrue(operation1.isCancelled, "It should be cancelled - state: \(operation1.state).")
    XCTAssertTrue(operation1.isFinished, "It should be finished - state: \(operation1.state).")
    XCTAssertEqual(operation1.errors.count, 1)

    XCTAssertFalse(group.isCancelled, "It should be cancelled - state: \(group.state).")
    XCTAssertTrue(group.isFinished, "It should be finished for state: \(group.state).")
    XCTAssertFalse(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 1)
  }

  func testOperationCancelledAsynchronously() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = CancellingAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = BlockOperation(block: { sleep(1)} )
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2)
    group.addCompletionBlock { expectation3.fulfill() }

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)

    group.start()

    XCTAssertFalse(group.isSuspended)

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertEqual(operation1.errors.count, 2)

    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertFalse(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 2)
  }

  func testBlockOperationCancelled() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledAsyncOperation()
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
    let operation1 = RunUntilCancelledAsyncOperation()
    operation1.addCompletionBlock {
      XCTAssertFalse(operation1.isExecuting)
      XCTAssertTrue(operation1.isCancelled, "It should be cancelled - state: \(operation1.state).")
      XCTAssertTrue(operation1.isFinished)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledAsyncOperation()
    operation2.addCompletionBlock {
      XCTAssertFalse(operation2.isExecuting)
      XCTAssertTrue(operation2.isCancelled, "It should be cancelled - state: \(operation1.state).")
      XCTAssertTrue(operation2.isFinished)
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation3 = RunUntilCancelledAsyncOperation()
    operation3.addCompletionBlock {
      XCTAssertFalse(operation3.isExecuting)
      XCTAssertTrue(operation3.isCancelled, "It should be cancelled - state: \(operation1.state).")
      XCTAssertTrue(operation3.isFinished)
      expectation3.fulfill()
    }

    let expectation4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.addCompletionBlock {
      XCTAssertFalse(group.isExecuting)
      XCTAssertTrue(group.isCancelled, "It should be cancelled - state: \(operation1.state).")
      XCTAssertTrue(group.isFinished)
      expectation4.fulfill()
    }

    group.start()
    group.cancel()

    waitForExpectations(timeout: 10)
  }

  func testGroupOperationCancelledWithError() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation1 = RunUntilCancelledAsyncOperation()
    operation1.completionBlock = {
      XCTAssertFalse(operation1.isExecuting)
      XCTAssertTrue(operation1.isCancelled)
      XCTAssertTrue(operation1.isFinished)
      XCTAssertEqual(operation1.errors.count, 0)
      expectation1.fulfill()
    }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = RunUntilCancelledAsyncOperation()
    operation2.completionBlock = {
      XCTAssertFalse(operation2.isExecuting)
      XCTAssertTrue(operation2.isCancelled)
      XCTAssertTrue(operation2.isFinished)
      XCTAssertEqual(operation2.errors.count, 0)
      expectation2.fulfill()
    }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation3 = RunUntilCancelledAsyncOperation()
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
    group.cancel(errors: [MockError.test])
    group.cancel(errors: [MockError.test])
    group.cancel(errors: [MockError.test])

    waitForExpectations(timeout: 10)
  }

  func testGroupOperationWithWaitUntilFinished() {
    let operation1 = BlockOperation(block: { sleep(2) } )
    let operation2 = BlockOperation(block: { sleep(2) } )
    let operation3 = BlockOperation(block: { sleep(2) } )
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
    let operation1 = BlockOperation { }
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group1, expectedValue: true)

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = BlockOperation(block: { sleep(1) } )

    let operation6 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group3 = GroupOperation(operations: operation6)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group3, expectedValue: true)

    let group2 = GroupOperation(operations: operation3, operation4, operation5, group3)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group2, expectedValue: true)

    let group4 = GroupOperation(operations: [])
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group4, expectedValue: true)

    let operation7 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)
    let group0 = GroupOperation(operations: group1, group2, operation7, group4)
    let expectation0 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group0, expectedValue: true)

    group0.name = "group0"
    group1.name = "group1"
    group2.name = "group2"
    group3.name = "group3"
    group4.name = "group4"

    group0.useOSLog(TestsLog)
    group1.useOSLog(TestsLog)
    group2.useOSLog(TestsLog)
    group3.useOSLog(TestsLog)
    group4.useOSLog(TestsLog)

    group0.start()

    wait(for: [expectation0, expectation1, expectation2, expectation3, expectation4], timeout: 10)

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

    group2.cancel(errors: [MockError.test])
    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isReady)
    XCTAssertFalse(group.isExecuting)
    XCTAssertFalse(group.isCancelled)
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

    XCTAssertFalse(operation1.isFinished)
    XCTAssertFalse(operation2.isFinished)
    XCTAssertFalse(group1.isFinished)
    XCTAssertFalse(operation3.isFinished)
    XCTAssertFalse(operation4.isFinished)
    XCTAssertFalse(operation5.isFinished)
    XCTAssertFalse(group2.isFinished)

    let group = GroupOperation(operations: group1, group2, operation6)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }
    group.useOSLog(TestsLog)
    group.cancel(errors: [MockError.test])
    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: [MockError.test])
  }

  func testCancelledGroupOperationsWithOnlyBlockOperations() {
    let operation1 = BlockOperation {  }
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2])
    group1.name = "group1"

    let operation3 = BlockOperation(block: { sleep(2) } )
    let operation4 = BlockOperation { }
    let operation5 = BlockOperation(block: { sleep(2) } )
    let group2 = GroupOperation(operations: operation3, operation4, operation5)
    group2.name = "group2"

    let operation6 = BlockOperation(block: { sleep(2) } )

    let group = GroupOperation(operations: group1, group2, operation6)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }
    group.name = "group"

    group.cancel(errors: [MockError.test])
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
    operation1.cancel(errors: [MockError.test])

    group1.name = "group1"

    let group = GroupOperation(operations: group1)
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group1.name = "group"

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
    operation3.cancel(errors: [MockError.failed])
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

    group1.useOSLog(TestsLog)
    group1.name = "GroupOperation1"

    group2.useOSLog(TestsLog)
    group2.name = "GroupOperation2"

    group.useOSLog(TestsLog)
    group.name = "GroupOperation"

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
    let operation1 = AdvancedBlockOperation { complete in complete([]) }

    let operation2 = AdvancedBlockOperation { complete in complete([]) }
    operation2.addCondition(NoFailedDependenciesCondition())

    let operation3 = AdvancedBlockOperation { complete in complete([]) }

    let adapterOperation = AdvancedBlockOperation { [unowned operation2] in
      operation2.cancel()
    }

    adapterOperation.addDependency(operation1)
    operation2.addDependency(adapterOperation)
    operation3.addDependency(operation2)

    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    adapterOperation.name = "adapterOperation"

    let group = GroupOperation(operations: [operation1, operation2, operation3, adapterOperation])
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)

    group.start()

    wait(for: [expectation1], timeout: 10)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation2.isFinished)
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
    let expectation2 = observer.didFinishExpectation
    group.addObserver(observer)

    group.addCompletionBlock { exepectation1.fulfill() }
    group.start()
    group.qualityOfService = .userInitiated

    wait(for: [exepectation1, expectation2], timeout: 10)

    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 0)
  }

  func testCancelledGroupOperationInsideAnotherQueue() {
    // cancel a group right after it has been added to the queue
    let queue = AdvancedOperationQueue()
    let operation = SleepyAsyncOperation(interval1: 6, interval2: 0, interval3: 0)
    let group = GroupOperation(operations: [operation])

    operation.name = "operation"
    group.name = "group"

    operation.useOSLog(TestsLog)
    group.useOSLog(TestsLog)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: group, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)
    queue.addOperation(group)

    DispatchQueue.global().asyncAfter(deadline: .now()) {
      group.cancel()
    }

    /**
     Failed due to expectation fulfilled in incorrect order: requires 'Expect value of 'finished' of <AdvancedOperationTests.SleepyAsyncOperation: 0x7f849764a010>{name = 'operation'} to be '1'', actually fulfilled 'Expect value of 'cancelled' of <AdvancedOperation.GroupOperation: 0x7f849764be90>{name = 'group'} to be '1''.
     **/
    /**
     - group operation is cancelled before operation is finished
     **/
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 12, enforceOrder: true)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(queue.operations.isEmpty)
  }

  func testCancelledGroupOperationInsideAnotherQueueWithDelay() {
    // cancel a group after a delay once it has been added to the queue
    let queue = AdvancedOperationQueue()
    let operation = SleepyAsyncOperation(interval1: 6, interval2: 0, interval3: 0)
    let group = GroupOperation(operations: [operation])
    let delay = 2.0

    operation.name = "operation"
    group.name = "group"

    operation.useOSLog(TestsLog)
    group.useOSLog(TestsLog)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: group, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)
    queue.addOperation(group)

    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
      group.cancel()
    }

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 12, enforceOrder: true)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(queue.operations.isEmpty)
  }

  func testExplicitProgress() {
    let operation1 = ProgressOperation()
    let operation2 = ProgressAsyncOperation()
    let operation3 = ProgressAsyncOperation()
    let operation4 = ProgressOperation()
    let operation5 = ProgressOperation()

    let expectation0 = self.expectation(description: "\(#function)\(#line)")
    let currentProgress = Progress(totalUnitCount: 1)
    let currentToken = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    let group = GroupOperation(operations: operation1, operation2, operation3, operation4)
    currentProgress.addChild(group.progress, withPendingUnitCount: 1)
    group.useOSLog(TestsLog)
    group.addOperation(operation: operation5, withProgressWeight: 4)

    operation1.name = "Operation1"
    operation2.name = "Operation2"
    operation3.name = "Operation3"
    operation4.name = "Operation4"
    operation5.name = "Operation5"

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)
    XCTAssertFalse(group.progress.isPausable)
    XCTAssertEqual(group.progress.totalUnitCount, 9)
    group.start()

    wait(for: [expectation0, expectation1], timeout: 30)


    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation1.progress.isFinished)

    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation2.progress.isFinished)

    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation3.progress.isFinished)

    XCTAssertTrue(operation4.isFinished)
    XCTAssertTrue(operation4.progress.isFinished)

    XCTAssertTrue(operation5.isFinished)
    XCTAssertTrue(operation5.progress.isFinished)

    currentToken.invalidate()
  }

  func testCancelledProgressPropagationToEveryChildProgress() {
    let operation1 = ProgressOperation()
    let operation2 = ProgressAsyncOperation()
    let operation3 = ProgressAsyncOperation()
    let operation4 = ProgressOperation()
    let operation5 = ProgressOperation()

    let currentProgress = Progress(totalUnitCount: 1)

    let group = GroupOperation(operations: operation1, operation2, operation3, operation4)
    group.maxConcurrentOperationCount = 1
    currentProgress.addChild(group.progress, withPendingUnitCount: 1)
    group.useOSLog(TestsLog)
    group.addOperation(operation: operation5, withProgressWeight: 4)
    operation1.name = "Operation1"
    operation2.name = "Operation2"
    operation3.name = "Operation3"
    operation4.name = "Operation4"
    operation5.name = "Operation5"

    let expectation0 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: group, expectedValue: true)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation4, expectedValue: true)
    let expectation5 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation5, expectedValue: true)

    let expectation6 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation7 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation8 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation9 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    let expectation10 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation5, expectedValue: true)


    XCTAssertEqual(group.progress.totalUnitCount, 9)

    currentProgress.cancel()

    wait(for: [
      expectation0, expectation1, expectation2, expectation3, expectation4, expectation5,
      expectation6, expectation7, expectation8, expectation9, expectation10
      ], timeout: 10)

    XCTAssertTrue(group.isCancelled)
    XCTAssertFalse(group.isFinished)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
    XCTAssertTrue(operation5.isFinished)

    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.progress.isCancelled)

    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation2.progress.isCancelled)

    XCTAssertTrue(operation3.isCancelled)
    XCTAssertTrue(operation3.progress.isCancelled)

    XCTAssertTrue(operation4.isCancelled)
    XCTAssertTrue(operation4.progress.isCancelled)

    XCTAssertTrue(operation5.isCancelled)
    XCTAssertTrue(operation5.progress.isCancelled)
  }

  func testOperationCancelledBeforeGroupCancellation() {
    let operation1 = RunUntilCancelledAsyncOperation()
    let group = GroupOperation(operations: operation1)
    group.useOSLog(TestsLog)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: group, expectedValue: true)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertFalse(group.isSuspended)

    operation1.cancel(errors: [MockError.test])
    group.cancel()

    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation1.isCancelled, "It should be cancelled - state: \(operation1.state).")
    XCTAssertTrue(operation1.isFinished, "It should be finished for state: \(operation1.state).")
    //XCTAssertEqual(operation1.errors.count, 1)

    XCTAssertTrue(group.isCancelled, "It should be cancelled - state: \(group.state).")
    XCTAssertFalse(group.isFinished)
    XCTAssertFalse(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 1)
    XCTAssertNil(group.duration)
  }

  /// Test to investigate the default behaviour of a cancelled operation added to a queue.
  func testBehaviourOfAnOperationCancelledAddedToAnOperationQueue() {
    let queue = OperationQueue()
    let operation = BlockOperation { }
    operation.cancel()

    queue.addOperation(operation)

    queue.waitUntilAllOperationsAreFinished()

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testDuration() {
    let operation1 = SleepyAsyncOperation() // 3 sec
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)

    let operation2 = BlockOperation(block: { sleep(1)} ) // 1
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)

    let group = GroupOperation(operations: operation1, operation2)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)

    group.maxConcurrentOperationCount = 1 // serial group: 3 + 1 + ∂

    group.start()

    wait(for: [expectation1, expectation2, expectation3], timeout: 10)

    XCTAssertFalse(group.isSuspended)
    XCTAssertTrue(group.isFinished)
    XCTAssertNotNil(group.duration)
    XCTAssertTrue(group.duration! >= 4.0 && group.duration! <= 5.5) // ∂ of 1.5 seconds (just in case)
  }

}
