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

final class NoFailedDependenciesConditionTests: XCTestCase {

  func testFinishedAndFailedOperation() {
    let queue = AdvancedOperationQueue()

    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"

    let operation2 = FailingAsyncOperation(errors: [.failed])
    operation2.name = "operation2"

    let operation3 = SleepyAsyncOperation()
    operation3.name = "operation3"

    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)

    operation1.addCondition(NoFailedDependenciesCondition())
    [operation4, operation3, operation2].then(operation1)

    XCTAssertFalse(operation1.isExecuting)
    XCTAssertFalse(operation2.isExecuting)
    XCTAssertFalse(operation3.isExecuting)
    XCTAssertFalse(operation4.isExecuting)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)

    XCTAssertTrue(operation1.hasErrors)
    XCTAssertEqual(operation1.errors.count, 2)
  }

  func testCancelledAndFailedOperation() {
    let queue = AdvancedOperationQueue()

    let operation1 = AdvancedBlockOperation { complete in complete([]) }
    operation1.name = "operation1"

    let operation2 = AdvancedBlockOperation { complete in complete([]) }
    operation2.name = "operation2"

    let operation3 = AdvancedBlockOperation { complete in complete([]) }
    operation3.name = "operation3"

    let operation4 = AdvancedBlockOperation { complete in complete([]) }
    operation4.name = "operation4"

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)

    operation2.cancel(errors: [MockError.failed])

    operation1.addCondition(NoFailedDependenciesCondition())
    [operation4, operation3, operation2].then(operation1)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)

    XCTAssertTrue(operation1.hasErrors)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertEqual(operation1.errors.count, 2)
  }

  func testCancelledAndFailedOperationWaitUntilFinished() {
    let queue = AdvancedOperationQueue()

    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"

    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    operation2.name = "operation2"

    let operation3 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    operation3.name = "operation3"

    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"

    operation2.cancel(errors: [MockError.failed])

    operation1.addCondition(NoFailedDependenciesCondition())
    [operation4, operation3, operation2].then(operation1)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)

    XCTAssertTrue(operation1.hasErrors)
    XCTAssertEqual(operation1.errors.count, 2)
  }

  func testIgnoredCancelledAndFailedOperation() {
    let queue = AdvancedOperationQueue()

    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"

    let operation2 = AdvancedBlockOperation { }
    operation2.name = "operation2"

    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"

    let operation4 = AdvancedBlockOperation { }
    operation4.name = "operation4"

    operation2.cancel(errors: [MockError.failed])

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)

    operation1.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))
    [operation4, operation3, operation2].then(operation1)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    XCTAssertFalse(operation1.hasErrors)
  }

  func testIgnoredCancelledAndFailedOperations() {
    let queue = AdvancedOperationQueue()

    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"

    let operation2 = AdvancedBlockOperation { }
    operation2.name = "operation2"

    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"

    let operation4 = FailingAsyncOperation(errors: [.failed, .cancelled(date: Date())])
    operation4.name = "operation4"

    operation2.cancel(errors: [MockError.failed])

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)

    operation1.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))
    [operation4, operation3, operation2].then(operation1)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)

    XCTAssertTrue(operation1.hasErrors)
    XCTAssertEqual(operation1.errors.count, 3)
  }

  func testFinishedAndFailedOperationNegated() {
    let queue = AdvancedOperationQueue()

    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"

    let operation2 = FailingAsyncOperation(errors: [.failed])
    operation2.name = "operation2"

    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"

    let operation4 = AdvancedBlockOperation { }
    operation4.name = "operation4"

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)

    operation1.addCondition(NegatedCondition(condition: NoFailedDependenciesCondition()))
    [operation4, operation3, operation2].then(operation1)
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)

    XCTAssertFalse(operation1.hasErrors)
  }

}
