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

final class AsynchronousOperationTests: XCTestCase {
  override class func setUp() {
    #if swift(<5.1)
    KVOCrashWorkaround.installFix()
    #endif
  }

  func testEarlyBailOut() {
    let operation = RunUntilCancelledAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [expectation1], timeout: 3)
  }

  func testSuccessfulExecution() {
    let operation = SleepyAsyncOperation() // by default is 3 second long
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    XCTAssertTrue(operation.isReady)

    operation.start()
    XCTAssertTrue(operation.isExecuting)

    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancelledExecution() {
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

  func testCancelledExecutionWithoutStarting() {
    let operation = SleepyAsyncOperation()

    XCTAssertTrue(operation.isReady)
    let expectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isCancelled), object: operation, expectedValue: true)
    operation.cancel()

    wait(for: [expectation], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
  }

  func testCancelledExecutionBeforeStart() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    XCTAssertTrue(operation.isReady)
    operation.cancel()
    operation.start()
    XCTAssertTrue(operation.isCancelled)

    operation.waitUntilFinished()

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancelledExecutionBeforeBeingAddedToOperationQueue() {
    let queue = OperationQueue()
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    queue.addOperation(operation)
    wait(for: [expectation1], timeout: 10)
  }

  func testMultipleCancel() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    let expectation2 = expectation(description: "\(#function)\(#line)")

    XCTAssertTrue(operation.isReady)
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

  func testMultipleConcurrentStartAfterCancellation() {
    let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
    operation.cancel()
    DispatchQueue.concurrentPerform(iterations: 100) { _ in
      operation.start()
    }
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testSecondStartAfterFinishOnDifferentThread() {
    let operation = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 0)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    XCTAssertTrue(operation.isReady)
    operation.start()
    wait(for: [expectation1], timeout: 10)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    DispatchQueue.global().async {
      operation.start() // There shouldn't be any crash
    }
  }

  //  func testSecondStartOnDifferentThreadAfterCancellation() {
  //    let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
  //    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
  //
  //    XCTAssertTrue(operation.isReady)
  //
  //    operation.start()
  //    operation.cancel()
  //    DispatchQueue.global().sync {
  //      operation.start()
  //    }
  //    wait(for: [expectation1], timeout: 10)
  //    XCTAssertTrue(operation.isFinished)
  //    operation.start()
  //  }
  //
  //  func testMultipleStartsOnTheSameThreadRaiseAnException() {
  //    let operation = InfiniteAsyncOperation()
  //    operation.start()
  //    operation.start()
  //  }
  //
  //  func testStartNotReadyOperation() {
  //    let operation = SleepyAsyncOperation()
  //    let operation2 = BlockOperation()
  //    operation.addDependency(operation2)
  //    operation.start()
  //  }

  // The readiness of operations is determined by their dependencies on other operations and potentially by custom conditions that you define.
  func testReadiness() {
    // Given
    let operation1 = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    XCTAssertTrue(operation1.isReady)

    let operation2 = BlockOperation { }
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
    XCTAssertFalse(operation1.isReady) // For an AsyncOperation, once it's started it won't be ready anymore
    XCTAssertTrue(operation2.isReady) // For a standard NSOperation, isReady is only determined by its depedendencies
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
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation2.name = "operation2"

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
    let operation1 = AutoCancellingAsyncOperation()
    operation1.name = "operation1"
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation2.name = "operation2"

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
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 2, interval3: 1)

    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"

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
    operation4.name = "DelayOperation<Cancelled>"

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4, conditionsOperationToLetOperationOneRun, conditionsOperationToLetOperationThreeRun], waitUntilFinished: true)

    XCTAssertTrue(operation4.isCancelled)
    XCTAssertFalse(operation2.isCancelled)
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
    let operation4 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation4.name = "operation4"

    operation1.completionBlock = { expectation1.fulfill() }
    operation2.completionBlock = { expectation2.fulfill() }
    operation3.completionBlock = { expectation3.fulfill() }
    operation4.completionBlock = { expectation4.fulfill() }

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
    XCTAssertTrue(operation3.isCancelled)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation1.isCancelled)
  }

  func testGate() {
    let operation0 = AutoCancellingAsyncOperation()
    let operation1 = BlockOperation()
    let operation2 = FailingOperation()
    let operation3 = AsyncBlockOperation { complete in
      XCTFail("It shouldn't be executed")
      complete()
    }
    let gate = GateOperation { [unowned operation3] gate in
      for op in gate.dependencies {
        if let failingOperation = op  as? FailingOperation, failingOperation.error != nil {
          operation3.cancel()
        }
      }
    }

    gate.addDependencies(operation1, operation2)
    operation3.addDependencies(gate)

    operation0.name = "op0"
    operation1.name = "op1"
    operation2.name = "op2"
    operation3.name = "op3"
    gate.name = "gate"
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 5
    queue.addOperations([operation0, operation1, operation2, operation3, gate], waitUntilFinished: true)
    XCTAssertTrue(operation3.isCancelled)
    XCTAssertTrue(operation3.isFinished)
  }

  func testStateChangeKVOSequenceIsEqualToOperation() {
    // Ensures that KVO events sequence for base Operation and AsyncOperation is the same
    struct Event: Equatable {
      let isPrior: Bool
      let oldValue: Bool?
      let newValue: Bool?
    }

    let operation = BlockOperation()
    let operation2 = AsynchronousBlockOperation { complete in complete() }
    let expectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)

    var eventsForOperation = [Event]()
    var eventsForOperation2 = [Event]()

    let tokenExecuting = operation.observe(\.isExecuting, options: [.prior,.old, .new]) { (op, change) in
      eventsForOperation.append(Event(isPrior: change.isPrior, oldValue: change.oldValue, newValue: change.newValue))
    }
    let tokenFinishing = operation.observe(\.isFinished, options: [.prior, .old, .new]) { (op, change) in
      eventsForOperation.append(Event(isPrior: change.isPrior, oldValue: change.oldValue, newValue: change.newValue))
    }

    let tokenExecuting2 = operation.observe(\.isExecuting, options: [.prior,.old, .new]) { (op, change) in
      eventsForOperation2.append(Event(isPrior: change.isPrior, oldValue: change.oldValue, newValue: change.newValue))
    }
    let tokenFinishing2 = operation.observe(\.isFinished, options: [.prior, .old, .new]) { (op, change) in
      eventsForOperation2.append(Event(isPrior: change.isPrior, oldValue: change.oldValue, newValue: change.newValue))
    }
    operation.start()
    operation2.start()

    wait(for: [expectation], timeout: 2)
    XCTAssertEqual(eventsForOperation, eventsForOperation2)
    tokenExecuting.invalidate()
    tokenExecuting2.invalidate()
    tokenFinishing.invalidate()
    tokenFinishing2.invalidate()
  }
}

final class GateOperation: Operation {
  private let block: (GateOperation) -> Void

  init(block: @escaping (GateOperation) -> Void) {
    self.block = block
  }

  override func main() {
    block(self)
  }
}
