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

final class AsynchronousOperationTests: XCTestCase {
  func testNotFinishingOperation() throws {
    let operation = NotFinishingAsynchronousOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    expectation1.isInverted = true
    operation.start()
    wait(for: [expectation1], timeout: 3)
  }

  func testEarlyBailOut() {
    let operation = RunUntilCancelledAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [expectation1], timeout: 3)
  }

  func testOutputBeforeStarting() throws {
    let operation = SleepyAsyncOperation()
    XCTAssertFalse(operation.isExecuting)

    // https://forums.swift.org/t/xctunwrap-not-available-during-swift-test/28878/4
    //let output = try XCTUnwrap(operation.output.failure) as NSError
    guard let output = operation.output.failure else {
      XCTFail("The operation should have a failure output")
      return
    }
    XCTAssertEqual(output as NSError, NSError.AdvancedOperation.noOutputYet)
  }

  func testStart() {
    let operation = SleepyAsyncOperation() // by default is 3 second long
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancel() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancelWithoutStarting() {
    let operation = SleepyAsyncOperation()

    XCTAssertTrue(operation.isReady)
    let expectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isCancelled), object: operation, expectedValue: true)
    operation.cancel()

    wait(for: [expectation], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
  }

  func testCancelBeforeStart() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    XCTAssertTrue(operation.isReady)

    operation.cancel()
    operation.start()
    XCTAssertTrue(operation.isCancelled)

    operation.waitUntilFinished()

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testMultipleCancel() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    let expectation2 = expectation(description: "\(#function)\(#line)")

    XCTAssertTrue(operation.isReady)
    operation.log = TestsLog
    operation.start()
    XCTAssertTrue(operation.isExecuting)

    DispatchQueue.global().async {
      operation.cancel()
      expectation2.fulfill()
    }
    operation.cancel()
    operation.cancel()
    XCTAssertTrue(operation.isCancelled)

    wait(for: [expectation1, expectation2], timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testFinishWithErrors() {
    let operation = FailingAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    operation.start()

    wait(for: [expectation1], timeout: 10)
    XCTAssertNotNil(operation.output.failure)
  }

  // The readiness of operations is determined by their dependencies on other operations and potentially by custom conditions that you define.
  func testReadiness() {
    // Given
    let operation1 = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    XCTAssertTrue(operation1.isReady)

    let operation2 = BlockOperation(block: { } )
    let expectation2 = expectation(description: "\(#function)\(#line)")
    operation2.addExecutionBlock { expectation2.fulfill() }

    // When
    operation1.addDependency(operation2)
    XCTAssertFalse(operation1.isReady)

    // Then
    operation2.start()
    XCTAssertTrue(operation1.isReady)
    operation1.start()

    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation1.isFinished)
  }

  // MARK: - OperationQueue

  func testEarlyBailOutInOperationQueue() {
    let queue = OperationQueue()
    queue.isSuspended = true
    let operation = RunUntilCancelledAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    operation.cancel()
    queue.isSuspended = false
    wait(for: [expectation1], timeout: 3)

    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)
  }

  func testDependencyNotCancellingDependantOperation() {
    let queue = OperationQueue()
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation1.name = "operation1"
    operation1.log = TestsLog
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation2.name = "operation2"
    operation2.log = TestsLog

    let conditionsOperation = BlockOperation { [unowned operation1, unowned operation2] in
      if operation1.isCancelled {
        operation2.cancel()
      }
    }

    conditionsOperation.addDependency(operation1)
    operation2.addDependency(conditionsOperation)

    queue.addOperations([operation1, operation2, conditionsOperation], waitUntilFinished: true)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertFalse(operation1.isCancelled)
    XCTAssertFalse(operation2.isCancelled)
  }

  func testDependencyCancellingDependantOperation() {
    let queue = OperationQueue()
    let operation1 = CancellingAsyncOperation()
    operation1.name = "operation1"
    operation1.log = TestsLog
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation2.name = "operation2"
    operation2.log = TestsLog

    let conditionsOperation = BlockOperation { [unowned operation1, unowned operation2] in
      if operation1.isCancelled {
        operation2.cancel()
      }
    }

    conditionsOperation.addDependency(operation1)
    operation2.addDependency(conditionsOperation)

    queue.addOperations([operation1, operation2, conditionsOperation], waitUntilFinished: true)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation2.isCancelled)
  }

  func testTwoLevelCondition() {
    let queue = OperationQueue()
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation3 = NotExecutableOperation()
    let operation4 = DelayOperation(interval: 0.2)

    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"

    operation1.log = TestsLog
    operation2.log = TestsLog
    operation3.log = TestsLog
    operation4.log = TestsLog

    let conditionsOperationToLetOperationOneRun = BlockOperation { [unowned operation2, unowned operation3] in
      if operation2.isCancelled || operation3.isCancelled {
        operation1.cancel()
      }
    }

    conditionsOperationToLetOperationOneRun.addDependencies(operation2, operation3)
    operation1.addDependencies(conditionsOperationToLetOperationOneRun)


    let conditionsOperationToLetOperationThreeRun = BlockOperation { [unowned operation4] in
      // this condition will fail and operation3 won't be executed
      if operation4.isCancelled {
        operation3.cancel()
      }
    }

    conditionsOperationToLetOperationThreeRun.addDependency(operation4)
    operation3.addDependency(conditionsOperationToLetOperationThreeRun)
    operation4.name = "DelayOperation - Cancelled"

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4, conditionsOperationToLetOperationOneRun, conditionsOperationToLetOperationThreeRun], waitUntilFinished: true)

    XCTAssertTrue(operation4.isCancelled)
    XCTAssertNotNil(operation3.output.failure)
    XCTAssertFalse(operation2.isCancelled)
    XCTAssertNotNil(operation1.output.failure)
    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.isFinished)
  }

  func testAllOperationCancelled() {
    let queue = OperationQueue()
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

    operation1.log = TestsLog
    operation2.log = TestsLog
    operation3.log = TestsLog
    operation4.log = TestsLog

    operation1.addCompletionBlock { expectation1.fulfill() }
    operation2.addCompletionBlock { expectation2.fulfill() }
    operation3.addCompletionBlock { expectation3.fulfill() }
    operation4.addCompletionBlock { expectation4.fulfill() }

    let conditionsOperationToLetOperationOneRun = BlockOperation { [unowned operation2, unowned operation3] in
      if operation2.isCancelled || operation3.isCancelled {
        operation1.cancel()
      }
    }

    conditionsOperationToLetOperationOneRun.addDependencies(operation2, operation3)
    operation1.addDependencies(conditionsOperationToLetOperationOneRun)

    let conditionsOperationToLetOperationFourRun = BlockOperation { [unowned operation4] in
      // this operation will fail
      if operation4.isCancelled {
        operation1.cancel()
      }
    }

    conditionsOperationToLetOperationFourRun.addDependency(operation4)
    operation3.addDependency(conditionsOperationToLetOperationFourRun)

    operation4.cancel()
    operation3.cancel()
    operation2.cancel()
    operation1.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4, conditionsOperationToLetOperationOneRun, conditionsOperationToLetOperationFourRun], waitUntilFinished: false)

    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation4.isCancelled)

    XCTAssertNotNil(operation3.output.failure)
    XCTAssertTrue(operation3.isCancelled)

    XCTAssertNotNil(operation2.output.failure)
    XCTAssertTrue(operation2.isCancelled)

    XCTAssertNotNil(operation1.output.failure)
    XCTAssertTrue(operation1.isCancelled)
  }
}