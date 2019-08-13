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

class MutualExclusivityConditionTests: XCTestCase {

  // TODO: add ExclusivityManager tests

  // MARK: - Enqueue Mode

  func testMutuallyExclusiveCondition() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    queue.qualityOfService = .userInitiated

    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)

    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    operation1.addCondition(condition)

    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 1)
    operation2.addCondition(condition)

    queue.addOperations([operation2, operation1], waitUntilFinished: true)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)

    XCTAssertFalse(operation1.isCancelled)
    XCTAssertFalse(operation2.isCancelled)
  }

  func testMutuallyExclusiveConditionInEnqueueModeUsingSerialQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .userInitiated

    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))

    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    operation1.addCondition(condition)

    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 1)
    operation2.addCondition(condition)

    queue.addOperations([operation2, operation1], waitUntilFinished: true)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)

    XCTAssertFalse(operation1.isCancelled)
    XCTAssertFalse(operation2.isCancelled)
  }

  func testMutuallyExclusiveConditionWithBlockOperations() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    // Using this condition, there aren't access races
    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))

    let operation1 = AdvancedBlockOperation { complete in
      text += "A"
      complete(nil)
    }
    operation1.addCondition(condition)
    operation1.completionBlock = {
      expectation1.fulfill()
    }

    let operation2 = AdvancedBlockOperation { complete in
      text += "A"
      complete(nil)
    }
    operation2.addCondition(condition)
    operation2.completionBlock = {
      expectation2.fulfill()
    }

    let operation3 = AdvancedBlockOperation {
      text += "A"
    }
    operation3.addCondition(condition)
    operation3.completionBlock = {
      expectation3.fulfill()
    }

    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
    /// An operation may start without waiting the completion block of the running one, so we cannot use `enforceOrder` to true.
    /// https://marcosantadev.com/4-ways-pass-data-operations-swift/
    wait(for: [expectation1, expectation2, expectation3], timeout: 10, enforceOrder: false)
    XCTAssertEqual(text, "AAA")
  }

  func testMultipleMutuallyExclusiveConditionsWithBlockOperations() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { complete in
      text += "A"
      complete(nil)
    }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition1)

    let operation2 = AdvancedBlockOperation { text += "A" }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition1)

    let operation3 = AdvancedBlockOperation { text += "A" }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)

    let operation4 = AdvancedBlockOperation { text += "A" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition1)
    operation4.addCondition(condition2)

    let operation5 = SleepyAsyncOperation(interval1: 2, interval2: 1, interval3: 2)
    operation5.completionBlock = {
      expectation5.fulfill()
    }
    operation5.addCondition(condition1)
    operation5.addCondition(condition2)

    queue.addOperations([operation1, operation2, operation3, operation4, operation5], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "AAAA") // no access races
  }

  func testMultipleMutuallyExclusiveConditionsWithGroupOperations() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A" }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.name = "operation1"
    operation1.log = TestsLog

    let operation2 = AdvancedBlockOperation { text += "A" }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.name = "operation2"
    operation2.log = TestsLog

    // operations inside a Group shouldn't have mutually exclusive conditions that
    let group1 = GroupOperation(operations: operation1, operation2)
    group1.addCondition(condition1)
    group1.name = "group1"
    group1.log = TestsLog


    let operation3 = AdvancedBlockOperation { text += "A" }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)
    operation3.name = "operation3"
    operation3.log = TestsLog

    let operation4 = AdvancedBlockOperation { text += "A" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition1)
    operation4.addCondition(condition2)
    operation4.name = "operation4"
    operation4.log = TestsLog

    queue.addOperations([group1, operation3, operation4], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "AAAA")
  }

  func testMultipleMutuallyExclusiveConditionsInsideGroupOperation() {
    var text = ""

    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A" }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition1)
    operation1.name = "operation1"
    operation1.log = TestsLog

    let operation2 = AdvancedBlockOperation { text += "A" }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition1)
    operation2.name = "operation2"
    operation2.log = TestsLog

    let operation3 = AdvancedBlockOperation { text += "A" }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)
    operation3.name = "operation3"
    operation3.log = TestsLog

    let operation4 = AdvancedBlockOperation { text += "A" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition1)
    operation4.addCondition(condition2)
    operation4.name = "operation4"
    operation4.log = TestsLog

    let group = GroupOperation(operations: operation1, operation2, operation3, operation4)
    group.maxConcurrentOperationCount = 10
    group.addCompletionBlock { expectation5.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "AAAA") // using conditions there aren't access races.
  }

  // MARK: - Cancel Mode

  func testMutuallyExclusiveConditionInCancelModeUsingSerialQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .userInitiated

    // being the operationQueue serial, the cancel condition is useless: everything should work normally

    let condition = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))

    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    operation1.addCondition(condition)

    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 1)
    operation2.addCondition(condition)

    queue.addOperations([operation2, operation1], waitUntilFinished: true)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)

    XCTAssertFalse(operation1.isCancelled)
    XCTAssertFalse(operation2.isCancelled)
  }

  func testMutuallyExclusiveConditionInCancelModeUsingInjection() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    queue.qualityOfService = .userInitiated
    let condition = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))

    let operation1 = IntToStringOperation()
    operation1.addCondition(condition)
    let operation2 = IntToStringOperation()
    operation2.addCondition(condition)
    operation1.input = 10
    operation1.injectOutput(into: operation2) { value -> Int? in
      if let value = value {
        return Int(value)
      } else {
        return nil
      }
    }

    // operation2 has operation1 has dependecy so they are executed serially: no cancellations due to the condition
    queue.addOperations([operation1, operation2], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, "10")
  }

  func testMutuallyExclusiveConditionWithCancelMode() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10

    // Every operation, if executed is ~6 seconds long, if we add all these operations together only one will be executed
    let condition = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))
    let operations = (0..<5).map { index -> AdvancedOperation in
      let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
      operation.addCondition(condition)
      operation.name = "Operation-\(index)"
      operation.log = TestsLog
      return operation
    }

    queue.addOperations(operations, waitUntilFinished: true)
    let cancelledOperationsCount = operations.filter { $0.isCancelled }.count
    XCTAssertEqual(cancelledOperationsCount, 4, "Only one operation should have been executed")
  }

  func testExclusivityManagerWithCancelModeAndMultipleOperationQueues() {
    let queue1 = OperationQueue()
    queue1.maxConcurrentOperationCount = 10

    let queue2 = OperationQueue()
    queue2.maxConcurrentOperationCount = 10

    // Every operation, if executed is ~6 seconds long, if we add all these operations together only one will be executed

    let condition = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))
    let operationsQueue1 = (0..<5).map { index -> AdvancedOperation in
      let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
      operation.addCondition(condition)
      operation.name = "OperationQueue1-\(index)"
      operation.log = TestsLog
      return operation
    }

    let operationsQueue2 = (0..<5).map { index -> AdvancedOperation in
      let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
      operation.addCondition(condition)
      operation.name = "OperationQueue2-\(index)"
      operation.log = TestsLog
      return operation
    }

    queue1.addOperations(operationsQueue1, waitUntilFinished: false)
    queue2.addOperations(operationsQueue2, waitUntilFinished: false)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(OperationQueue.operationCount), object: queue1, expectedValue: 0)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(OperationQueue.operationCount), object: queue2, expectedValue: 0)

    wait(for: [expectation1, expectation2], timeout: 10)

    let cancelledOperationsCount1 = operationsQueue1.filter { $0.isCancelled }.count
    let cancelledOperationsCount2 = operationsQueue2.filter { $0.isCancelled }.count
    XCTAssertEqual(cancelledOperationsCount1 + cancelledOperationsCount2, 9, "Only one operation should have been executed")
  }
}
