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

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.qualityOfService = .userInitiated
    groupOperation.installLogger()
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    wait(for: [expectation1], timeout: 5)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertEqual(groupOperation.qualityOfService, .userInitiated)
  }

  func testExecutionWithNestedGroupOperation() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = SleepyAsyncOperation()

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()
    operation4.installLogger()

    let groupOperation1 = GroupOperation(operations: operation1, operation2)
    let groupOperation2 = GroupOperation(operations: operation3, operation4)
    let groupOperation3 = GroupOperation(operations: groupOperation1, groupOperation2)
    groupOperation3.qualityOfService = .userInitiated
    groupOperation3.installLogger()

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
    let operation3 = BlockOperation()

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.maxConcurrentOperationCount = 1
    groupOperation.installLogger()

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    wait(for: [expectation1], timeout: 15)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertEqual(groupOperation.maxConcurrentOperationCount, 1)
  }

  func testCancelledExecution() {
    let operation1 = RunUntilCancelledAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installLogger()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.start()
    groupOperation.cancel()

    wait(for: [expectation1], timeout: 5)
  }

  func testCancelledExecutionBeforeStarting() {
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installLogger()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.cancel()
    groupOperation.start()

    wait(for: [expectation1], timeout: 5)
  }

  func testExecutionWhileGeneratingAdditionalOperationsOnTargetQueue() {
    let queue = OperationQueue()
    let expectation0 = self.expectation(description: "Generated operations completed")
    expectation0.expectedFulfillmentCount = 6
    
    let groupOperation = LazyGroupOperation(targetQueue: queue) { () -> [Operation] in
      let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
      let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
      let operation3 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
   
      operation1.installLogger()
      operation2.installLogger()
      operation3.installLogger()
      operation3.addDependency(operation2)

      operation1.name = "op1"
      operation2.name = "op2"
      operation3.name = "op3"
      
      operation1.completionBlock = { expectation0.fulfill() }
      operation2.completionBlock = { expectation0.fulfill() }
      operation3.completionBlock = { expectation0.fulfill() }

      let operation4 = OperationsGenerator { () -> [Operation] in
        let operation5 = OperationsGenerator { () -> [Operation] in
          let operation6 = BlockOperation { }
          operation6.name = "op6"
          operation6.installLogger()
          operation6.completionBlock = { expectation0.fulfill() }
          return [operation6]
        }
        operation5.name = "op5"
        operation5.installLogger()
        operation5.completionBlock = { expectation0.fulfill() }
        return [operation5]
      }

      operation4.name = "op4"
      operation4.installLogger()
      operation4.completionBlock = { expectation0.fulfill() }

      return [operation1, operation2, operation3, operation4]
    }
    
    groupOperation.installLogger()
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    queue.addOperation(groupOperation)
    wait(for: [expectation0, expectation1], timeout: 5)
  }

  func testExecutionOnOperationQueue() {
    let queue = OperationQueue()
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installLogger()
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

    operation1.installLogger()
    operation2.installLogger()
    operation3.installLogger()
    operation4.installLogger()

    let groupOperation = GroupOperation(operations: operation1, operation2, operation3)
    groupOperation.installLogger()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    groupOperation.cancel()
    queue.addOperation(groupOperation)

    wait(for: [expectation1], timeout: 5)
  }
}

class IOGroupOperation: GroupOperation, InputConsumingOperation, OutputProducingOperation {
  var input: Int? {
    set {
      initialOperation.input = newValue
    }
    get {
      return initialOperation.input
    }
  }
  var output: Int? {
    return finalOperation.output
  }

  private let initialOperation: IntToStringOperation
  private let finalOperation: StringToIntOperation

  init(test: String) {
    finalOperation.addDependency(initialOperation)
    super.init(operations: initialOperation, finalOperation)
  }

//  override init(underlyingQueue: OperationQueue? = nil, operations: [Operation]) {
//    super.init(operations: operations)
//    let b = BlockOperation { [unowned self] in
//      self.output = nil
//    }
//  }
}
