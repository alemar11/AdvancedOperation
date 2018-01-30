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

#if !os(Linux)

  import XCTest
  @testable import AdvancedOperation

  class GroupOperationTests: XCTestCase {

    func testFlow() {
      let expectation1 = expectation(description: "\(#function)\(#line)")
      let operation1 = SleepyAsyncOperation()
      operation1.addCompletionBlock { expectation1.fulfill() }

      let expectation2 = expectation(description: "\(#function)\(#line)")
      let operation2 = BlockOperation(block: { sleep(1)} )
      operation2.addCompletionBlock { expectation2.fulfill() }

      let expectation3 = expectation(description: "\(#function)\(#line)")
      let group = GroupOperation(operations: operation1, operation2)
      group.addCompletionBlock { expectation3.fulfill() }

      group.start()
      waitForExpectations(timeout: 10)

      XCTAssertOperationFinished(operation: group)
    }

    func testOperationCancelled() {
      let expectation1 = expectation(description: "\(#function)\(#line)")
      let operation1 = SleepyAsyncOperation()
      operation1.addCompletionBlock { expectation1.fulfill() }

      let expectation2 = expectation(description: "\(#function)\(#line)")
      let operation2 = BlockOperation(block: { sleep(1)} )
      operation2.addCompletionBlock { expectation2.fulfill() }

      let expectation3 = expectation(description: "\(#function)\(#line)")
      let group = GroupOperation(operations: operation1, operation2)
      group.addCompletionBlock {
        expectation3.fulfill()
      }

      group.start()
      operation1.cancel(error: MockError.test)
      waitForExpectations(timeout: 10)

      XCTAssertOperationCancelled(operation: operation1, errors: [MockError.test])
      XCTAssertOperationFinished(operation: group, errors: [MockError.test])

      XCTAssertEqual(group.aggregatedErrors.count, 1)
    }

    func testBlockOperationCancelled() {
      let expectation1 = expectation(description: "\(#function)\(#line)")
      let operation1 = SleepyAsyncOperation()
      operation1.addCompletionBlock { expectation1.fulfill() }

      let expectation2 = expectation(description: "\(#function)\(#line)")
      let operation2 = BlockOperation(block: { sleep(1)} )
      operation2.addCompletionBlock { expectation2.fulfill() }

      let expectation3 = expectation(description: "\(#function)\(#line)")
      let group = GroupOperation(operations: operation1, operation2)
      group.addCompletionBlock {
        expectation3.fulfill()
      }

      group.start()
      operation2.cancel()
      waitForExpectations(timeout: 10)

      XCTAssertOperationFinished(operation: operation1)
      XCTAssertOperationFinished(operation: group)
      XCTAssertEqual(group.aggregatedErrors.count, 0)

    }

    func testGroupOperationCancelled() {
      let expectation1 = expectation(description: "\(#function)\(#line)")
      let operation1 = BlockOperation(block: { sleep(2)} )
      operation1.addCompletionBlock { expectation1.fulfill() }

      let expectation2 = expectation(description: "\(#function)\(#line)")
      let operation2 = BlockOperation(block: { sleep(2)} )
      operation2.addCompletionBlock { expectation2.fulfill() }

      let expectation3 = expectation(description: "\(#function)\(#line)")
      let operation3 = BlockOperation(block: { sleep(2)} )
      operation3.addCompletionBlock { expectation3.fulfill() }

      let expectation4 = expectation(description: "\(#function)\(#line)")
      let group = GroupOperation(operations: operation1, operation2, operation3)
      group.addCompletionBlock { expectation4.fulfill() }

      group.start()
      group.cancel()

      waitForExpectations(timeout: 10)

      for operation in [operation1, operation2, operation3, group] {
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
        if let advancedOperation = operation as? AdvancedOperation {
          XCTAssertOperationCancelled(operation: advancedOperation)
        }
      }
    }

    func testGroupOperationCancelledWithError() {
      let expectation1 = expectation(description: "\(#function)\(#line)")
      let operation1 = BlockOperation(block: { sleep(2)} )
      operation1.addCompletionBlock { expectation1.fulfill() }

      let expectation2 = expectation(description: "\(#function)\(#line)")
      let operation2 = BlockOperation(block: { sleep(2)} )
      operation2.addCompletionBlock { expectation2.fulfill() }

      let expectation3 = expectation(description: "\(#function)\(#line)")
      let operation3 = BlockOperation(block: { sleep(2)} )
      operation3.addCompletionBlock { expectation3.fulfill() }

      let expectation4 = expectation(description: "\(#function)\(#line)")
      let group = GroupOperation(operations: operation1, operation2, operation3)
      group.addCompletionBlock { expectation4.fulfill() }

      group.start()
      group.cancel(error: MockError.test)

      waitForExpectations(timeout: 10)

      for operation in [operation1, operation2, operation3, group] {
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
        if let groupOperation = operation as? GroupOperation {
          XCTAssertEqual(groupOperation.errors.count, 1)
          XCTAssertEqual(groupOperation.aggregatedErrors.count, 0)
        } else if let advancedOperation = operation as? AdvancedOperation {
          XCTAssertEqual(advancedOperation.errors.count, 0)
        }
      }
    }

    // FIXME: timeout with waitUntilFinished on Travis CI

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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group.start()
      waitForExpectations(timeout: 10)

      XCTAssertOperationFinished(operation: group)
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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group2.cancel(error: MockError.test)
      group.start()
      waitForExpectations(timeout: 10)

      XCTAssertOperationFinished(operation: group, errors: [MockError.test])
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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group.cancel(error: MockError.test)
      group.start()
      waitForExpectations(timeout: 10)

      XCTAssertOperationCancelled(operation: group, errors: [MockError.test])
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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group.start()
      waitForExpectations(timeout: 10)
      XCTAssertOperationFinished(operation: group, errors: errors)

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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group.start()
      operation3.cancel(error: MockError.failed)
      waitForExpectations(timeout: 10)

      XCTAssertOperationCancelled(operation: operation3, errors: [MockError.failed])
      XCTAssertOperationFinished(operation: group, errors:  [MockError.test, MockError.failed, MockError.failed, MockError.failed])
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
      group.addCompletionBlock {
        exepectation1.fulfill()
      }

      group.start()
      waitForExpectations(timeout: 10)

      XCTAssertOperationFinished(operation: group, errors: errors1 + errors2 )
    }

    /**
     TODO:
     - failing nested group operation
     - cancelled group operation
     - cancelled nested group operation
     **/

  }

#endif
