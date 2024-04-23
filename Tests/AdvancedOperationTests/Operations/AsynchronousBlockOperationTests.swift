// AdvancedOperation

import XCTest

@testable import AdvancedOperation

final class AsynchronousBlockOperationTests: XCTestCase {
  func testCancelledExecutionBeforeStarting() {
    let operation = AsynchronousBlockOperation { complete in
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        complete()
      }
    }
    XCTAssertTrue(operation.isAsynchronous)
    XCTAssertTrue(operation.isConcurrent)
    let expectation1 = XCTKVOExpectation(
      keyPath: #keyPath(Operation.isFinished),
      object: operation,
      expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [expectation1], timeout: 4)
    XCTAssertTrue(operation.isCancelled)
  }

  func testBlockOperationCompletedInAsyncQueue() {
    let operation = AsynchronousBlockOperation { complete in
      XCTAssertTrue(Thread.isMainThread)
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        complete()
      }
    }
    let expectation1 = XCTKVOExpectation(
      keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [expectation1], timeout: 4)
  }

  func testBlockOperationWithAnAsyncQueueInside() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation = AsynchronousBlockOperation { complete in
      DispatchQueue.global().async {
        sleep(1)
        expectation1.fulfill()
        complete()
      }
    }
    operation.completionBlock = { expectation2.fulfill() }
    operation.start()
    wait(for: [expectation1, expectation2], timeout: 10, enforceOrder: true)
  }

  @MainActor
  func testComposition() {
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()

    operation3.completionBlock = { expectation3.fulfill() }
    let adapterOperation = AsynchronousBlockOperation { complete in
      operation2.cancel()
      complete()
    }
    adapterOperation.addDependency(operation1)
    operation2.addDependency(adapterOperation)
    operation3.addDependency(operation2)
    let queue = OperationQueue()
    queue.addOperations([operation1, operation2, operation3, adapterOperation], waitUntilFinished: false)

    waitForExpectations(timeout: 10)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(adapterOperation.isFinished)
  }

  @MainActor
  func testMemoryLeak() {
    class Dummy: @unchecked Sendable { }
    var object = Dummy()
    weak var weakObject = object

    autoreleasepool {
      var operation = AsynchronousBlockOperation { [unowned object] complete in
        DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).async {
          _ = object
          complete()
        }
      }

      let expectation1 = expectation(description: "\(#function)\(#line)")
      operation.completionBlock = { expectation1.fulfill() }
      operation.start()

      waitForExpectations(timeout: 3)

      // Memory leaks test: once the operation is released, the captured object (by reference) should be nil (weakObject)
      operation = AsynchronousBlockOperation { _ in }
      object = Dummy()
    }

    XCTAssertNil(weakObject, "Memory leak: the object should have been deallocated at this point.")
  }
}
