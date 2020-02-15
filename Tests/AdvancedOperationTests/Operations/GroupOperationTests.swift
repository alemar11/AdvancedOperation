//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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
  override class func setUp() {
    #if swift(<5.1)
    AdvancedOperation.KVOCrashWorkaround.installFix()
    #endif
  }

  func testSuccessfulExecution() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.qualityOfService = .userInitiated
    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    wait(for: [expectation1], timeout: 5)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
    XCTAssertEqual(groupOperation.qualityOfService, .userInitiated)
  }

  func testExecutionWithNestedGroupOperation() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation1 = GroupOperation(operations: operation1, operation2)
    let groupOperation2 = GroupOperation(operations: operation3, operation4)
    let groupOperation3 = GroupOperation(operations: groupOperation1, groupOperation2)
    groupOperation3.qualityOfService = .userInitiated
    groupOperation3.installTracker()

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation3, expectedValue: true)
    groupOperation3.start()
    wait(for: [expectation1], timeout: 5)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
  }

  func testSuccessfulExecutionWithMaxConcurrentOperationCountToOne() {
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    let operation3 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    let operation5 = BlockOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()
    operation5.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.maxConcurrentOperationCount = 1
    groupOperation.installTracker()
    groupOperation.addOperations(operation4, operation5)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    wait(for: [expectation1], timeout: 15)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
    XCTAssertEqual(groupOperation.maxConcurrentOperationCount, 1)
  }

  func testCancelledExecution() {
    let operation1 = RunUntilCancelledAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    groupOperation.cancel()

    wait(for: [expectation1], timeout: 5)
  }

  func testCancelledExecutionBeforeStarting() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.cancel()
    groupOperation.start()

    wait(for: [expectation1], timeout: 5)
  }

  //  func testLazyStart() {
  //    let groupOperation = LazyGroupOperation { () -> [Operation] in
  //      let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
  //      let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
  //      let operation3 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
  //
  //      operation1.installTracker()
  //      operation2.installTracker()
  //      operation3.installTracker()
  //      operation3.addDependency(operation2)
  //
  //      operation1.name = "op1"
  //      operation2.name = "op2"
  //      operation3.name = "op3"
  //
  //      return [operation1, operation2, operation3]
  //    }
  //
  //    let operation4 = BlockOperation { }
  //    operation4.installTracker()
  //    operation4.name = "op4"
  //
  //    groupOperation.installTracker()
  //    groupOperation.addOperation(operation: operation4)
  //    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
  //    groupOperation.start()
  //    wait(for: [expectation1], timeout: 5)
  //  }

  func testExecutionWhileGeneratingAdditionalOperations() {
    let groupOperation = LazyGroupOperation { () -> [Operation] in
      let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
      let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
      let operation3 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)

      operation1.installTracker()
      operation2.installTracker()
      operation3.installTracker()
      operation3.addDependency(operation2)

      operation1.name = "op1"
      operation2.name = "op2"
      operation3.name = "op3"

      let operation5 = OperationsGenerator { () -> [Operation] in
        let operation6 = OperationsGenerator { () -> [Operation] in
          let operation7 = BlockOperation { }
          operation7.name = "op7"
          operation7.installTracker()
          return [operation7]
        }
        operation6.name = "op6"
        operation6.installTracker()
        return [operation6]
      }

      operation5.name = "op5"
      operation5.installTracker()

      return [operation1, operation2, operation3, operation5]
    }

    let operation4 = BlockOperation { }
    operation4.installTracker()
    operation4.name = "op4"

    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    wait(for: [expectation1], timeout: 5)
  }

  func testExecutionOnOperationQueue() {
    let queue = OperationQueue()
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    queue.addOperation(groupOperation)

    wait(for: [expectation1], timeout: 5)
  }

  func testCancelledExecutionOnOperationQueue() {
    let queue = OperationQueue()
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installTracker()
    operation2.installTracker()
    operation3.installTracker()
    operation4.installTracker()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installTracker()
    groupOperation.addOperation(operation4)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.cancel()
    queue.addOperation(groupOperation)

    wait(for: [expectation1], timeout: 5)
  }
}
