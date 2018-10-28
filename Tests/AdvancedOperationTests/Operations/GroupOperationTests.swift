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

  func testStart() {
    let operation1 = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)

    let operation2 = BlockOperation(block: { sleep(1)} )
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)

    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertTrue(group.isSuspended)

    group.start()

    wait(for: [expectation1, expectation2, expectation3], timeout: 10)

    XCTAssertTrue(group.isSuspended)
    XCTAssertTrue(group.isFinished)
  }

  func testCancel() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = AdvancedBlockOperation { complete in
      sleep(1)
      complete([])
    }

    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isSuspended), object: group, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isCancelled), object: group, expectedValue: true)

    operation1.name = "operation1"
    operation1.useOSLog(TestsLog)

    operation2.name = "operation2"
    operation2.useOSLog(TestsLog)

    group.name = "group"
    group.useOSLog(TestsLog)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertTrue(group.isSuspended)

    group.cancel()

    wait(for: [expectation1, expectation2], timeout: 10)

    /// These operations are finished because the queue they are running into is cancelled and suspended
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished) // an operation that is not yet started or executing cannot be finished

    XCTAssertTrue(group.isCancelled)
    XCTAssertFalse(group.isFinished) /// an operation that is not yet started or that is executing can't be finished (in this case we are in the first situation)
  }

  func testStartAfterCancel() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = AdvancedBlockOperation { complete in
      sleep(1)
      complete([])
    }

    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isSuspended), object: group, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isCancelled), object: group, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isFinished), object: group, expectedValue: true)

    operation1.name = "operation1"
    operation1.useOSLog(TestsLog)

    operation2.name = "operation2"
    operation2.useOSLog(TestsLog)

    group.name = "group"
    group.useOSLog(TestsLog)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertTrue(group.isSuspended)

    group.cancel()
    group.start()

    wait(for: [expectation1, expectation2, expectation3], timeout: 10)

    /// These operations are finished because the queue they are running into is cancelled and suspended
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(group.isSuspended)
    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
  }

  func testOperationCancelled() {
    let operation1 = RunUntilCancelledOperation()
    let operation2 = BlockOperation { }
    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(GroupOperation.isSuspended), object: group, expectedValue: true)

    XCTAssertEqual(group.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
    XCTAssertTrue(group.isSuspended)

    group.start()
    operation1.cancel(errors: [MockError.test])

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)

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
    let operation1 = CancellingAsyncOperation()
    operation1.addCompletionBlock { expectation1.fulfill() }

    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation2 = BlockOperation(block: { sleep(1)} )
    operation2.addCompletionBlock { expectation2.fulfill() }

    let expectation3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
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
    XCTAssertTrue(group.isSuspended)
    XCTAssertEqual(group.aggregatedErrors.count, 2)
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
    let group = GroupOperation(operations: operation1, operation2, operation3, exclusivityManager: ExclusivityManager())
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
    let group = GroupOperation(operations: operation1, operation2, operation3, exclusivityManager: ExclusivityManager())
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
    let group = GroupOperation(operations: operation1, operation2, operation3, exclusivityManager: ExclusivityManager())
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
    let operation1 = BlockOperation(block: { sleep(2)} )
    let operation2 = BlockOperation(block: { sleep(2)} )
    let operation3 = BlockOperation(block: { sleep(2)} )
    let group = GroupOperation(operations: operation1, operation2, operation3, exclusivityManager: ExclusivityManager())

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
    let group1 = GroupOperation(operations: [operation1, operation2], exclusivityManager: ExclusivityManager())

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = BlockOperation(block: { sleep(1) } )
    let group2 = GroupOperation(operations: operation3, operation4, operation5, exclusivityManager: ExclusivityManager())

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    let group = GroupOperation(operations: group1, group2, operation6, exclusivityManager: ExclusivityManager())
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isFinished)
  }


  func testMultipleNestedGroupOperations() { // TODO: test crashed
    let operation1 = BlockOperation { }
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2], exclusivityManager: ExclusivityManager())
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group1, expectedValue: true)

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = BlockOperation(block: { sleep(1) } )

    let operation6 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group3 = GroupOperation(operations: operation6, exclusivityManager: ExclusivityManager())
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group3, expectedValue: true)

    let group2 = GroupOperation(operations: operation3, operation4, operation5, group3, exclusivityManager: ExclusivityManager())
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group2, expectedValue: true)

    let group4 = GroupOperation(operations: [], exclusivityManager: ExclusivityManager())
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: group4, expectedValue: true)

    let operation7 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)
    let group0 = GroupOperation(operations: group1, group2, operation7, group4, exclusivityManager: ExclusivityManager())
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
    let group1 = GroupOperation(operations: [operation1, operation2], exclusivityManager: ExclusivityManager())

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group2 = GroupOperation(operations: operation3, operation4, operation5, exclusivityManager: ExclusivityManager())

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    let group = GroupOperation(operations: group1, group2, operation6, exclusivityManager: ExclusivityManager())
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

    group2.cancel(errors: [MockError.test])
    group.start()
    waitForExpectations(timeout: 10)

    XCTAssertTrue(group.isReady)
    XCTAssertFalse(group.isExecuting)
    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)

    let op = BlockOperation {}
    op.cancel()
    print(op)
  }

  func testGroupOperationsCancelled() {
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = BlockOperation(block: { sleep(2) } )
    let group1 = GroupOperation(operations: [operation1, operation2], exclusivityManager: ExclusivityManager())

    let operation3 = SleepyOperation()
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation5 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let group2 = GroupOperation(operations: operation3, operation4, operation5, exclusivityManager: ExclusivityManager())

    let operation6 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)

    XCTAssertFalse(operation1.isFinished)
    XCTAssertFalse(operation2.isFinished)
    XCTAssertFalse(group1.isFinished)
    XCTAssertFalse(operation3.isFinished)
    XCTAssertFalse(operation4.isFinished)
    XCTAssertFalse(operation5.isFinished)
    XCTAssertFalse(group2.isFinished)

    let group = GroupOperation(operations: group1, group2, operation6, exclusivityManager: ExclusivityManager())
    let exepectation1 = expectation(description: "\(#function)\(#line)")
    group.addCompletionBlock { exepectation1.fulfill() }

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
    let group1 = GroupOperation(operations: [operation1, operation2], exclusivityManager: ExclusivityManager())
    group1.name = "group1"

    let operation3 = BlockOperation(block: { sleep(2) } )
    let operation4 = BlockOperation { }
    let operation5 = BlockOperation(block: { sleep(2) } )
    let group2 = GroupOperation(operations: operation3, operation4, operation5, exclusivityManager: ExclusivityManager())
    group2.name = "group2"

    let operation6 = BlockOperation(block: { sleep(2) } )

    let group = GroupOperation(operations: group1, group2, operation6, exclusivityManager: ExclusivityManager())
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
    let group1 = GroupOperation(operations: operation1, exclusivityManager: ExclusivityManager())
    operation1.cancel(errors: [MockError.test])

    group1.name = "group1"

    let group = GroupOperation(operations: group1, exclusivityManager: ExclusivityManager())
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
    let group1 = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors)
    let group2 = GroupOperation(operations: operation3, operation4, exclusivityManager: ExclusivityManager())

    let group = GroupOperation(operations: group1, group2, exclusivityManager: ExclusivityManager())
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
    let group1 = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors)
    let group2 = GroupOperation(operations: operation3, operation4, exclusivityManager: ExclusivityManager())

    let group = GroupOperation(operations: group1, group2, exclusivityManager: ExclusivityManager())
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
    let group1 = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())

    let operation3 = SleepyAsyncOperation()
    let operation4 = FailingAsyncOperation(errors: errors2)
    let group2 = GroupOperation(operations: operation3, operation4, exclusivityManager: ExclusivityManager())

    let group = GroupOperation(operations: group1, group2, exclusivityManager: ExclusivityManager())
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
    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
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

    let group = GroupOperation(operations: [operation1, operation2, operation3, adapterOperation], exclusivityManager: ExclusivityManager())
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

    let group = GroupOperation(operations: [operation1, operation2, operation3, adapterOperation], exclusivityManager: ExclusivityManager())
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
    let group = GroupOperation(operations: operation1, exclusivityManager: ExclusivityManager())
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
    let group = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
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

}
