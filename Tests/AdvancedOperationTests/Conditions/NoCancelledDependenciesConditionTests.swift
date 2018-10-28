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

final class NoCancelledDependenciesConditionTests: XCTestCase {

  func testTwoLevelCondition() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)

    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation3 = NotExecutableOperation()
    let operation4 = DelayOperation(interval: 0.2)

    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"

    operation1.useOSLog(TestsLog)
    operation2.useOSLog(TestsLog)
    operation3.useOSLog(TestsLog)
    operation4.useOSLog(TestsLog)

    operation1.addDependencies([operation2, operation3])
    operation1.addCondition(NoCancelledDependeciesCondition())
    operation3.addDependency(operation4)
    operation3.addCondition(NoCancelledDependeciesCondition()) // this condition will fail and operation3 won't be executed
    operation4.name = "DelayOperation - Cancelled"

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)

    XCTAssertTrue(operation4.isCancelled)
    XCTAssertTrue(operation3.hasErrors)
    XCTAssertFalse(operation2.isCancelled)
    XCTAssertTrue(operation1.hasErrors)
    XCTAssertTrue(operation1.isCancelled)
  }

  func testAllOperationCancelled() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyAsyncOperation()
    operation1.name = "operation1"
    let operation2 = SleepyAsyncOperation()
    operation2.name = "operation2"
    let operation3 = NotExecutableOperation()
    operation3.name = "operation3"
    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"

    operation1.useOSLog(TestsLog)
    operation2.useOSLog(TestsLog)
    operation3.useOSLog(TestsLog)
    operation4.useOSLog(TestsLog)

    operation1.addCompletionBlock { expectation1.fulfill() }
    operation2.addCompletionBlock { expectation2.fulfill() }
    operation3.addCompletionBlock { expectation3.fulfill() }
    operation4.addCompletionBlock { expectation4.fulfill() }

    operation1.addDependencies([operation2, operation3])
    operation1.addCondition(NoCancelledDependeciesCondition())
    operation3.addDependency(operation4)
    operation3.addCondition(NoCancelledDependeciesCondition()) // this operation will fail

    operation4.cancel()
    operation3.cancel()
    operation2.cancel()
    operation1.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation4.isCancelled)

    XCTAssertFalse(operation3.hasErrors)
    XCTAssertTrue(operation3.isCancelled)

    XCTAssertFalse(operation2.hasErrors)
    XCTAssertTrue(operation2.isCancelled)

    XCTAssertFalse(operation1.hasErrors)
    XCTAssertTrue(operation1.isCancelled)
  }

  func testWithNoFailedDependeciesCondition() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)

    let operation1 = NotExecutableOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = NotExecutableOperation()
    let operation4 = DelayOperation(interval: 1)

    operation1.name = "op1"
    operation2.name = "op2"
    operation3.name = "op3"
    operation4.name = "op4"

    operation1.useOSLog(TestsLog)

    operation1.addDependencies([operation2, operation3])
    operation1.addCondition(NoCancelledDependeciesCondition())
    operation1.addCondition(NoFailedDependenciesCondition())
    operation3.addDependency(operation4)
    operation3.addCondition(NoCancelledDependeciesCondition())

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)

    XCTAssertTrue(operation4.isCancelled)
    XCTAssertFalse(operation4.hasErrors)

    XCTAssertTrue(operation3.hasErrors)
    XCTAssertTrue(operation3.isCancelled)
    XCTAssertTrue(operation3.isFinished)

    XCTAssertFalse(operation2.isCancelled)
    XCTAssertFalse(operation2.hasErrors)

    XCTAssertTrue(operation1.hasErrors)
    XCTAssertTrue(operation1.isCancelled)
  }

}
