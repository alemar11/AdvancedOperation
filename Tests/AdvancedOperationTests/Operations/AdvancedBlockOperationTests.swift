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

final class AdvancedBlockOperationTests: XCTestCase {
  func testCancel() {
    let operation = AsynchronousBlockOperation<Void> { complete in
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        complete(.success(()))
      }
    }
    XCTAssertTrue(operation.isAsynchronous)
    XCTAssertTrue(operation.isConcurrent)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    operation.cancel()

    wait(for: [expectation1], timeout: 4)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertEqual(operation.name, "AsynchronousBlockOperation <()>")
  }

  func testInitializerWithQueue() {
    let operation = AsynchronousBlockOperation<Int>(queue: .main) {
      return .success(11)
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [expectation1], timeout: 4)
    XCTAssertEqual(operation.output?.success, 11)
    XCTAssertEqual(operation.name, "AsynchronousBlockOperation <Int>")
  }

  func testCancelBeforeStarting() {
    let operation = AsynchronousBlockOperation<Void> { complete in
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        complete(.success(()))
      }
    }
    XCTAssertTrue(operation.isAsynchronous)
    XCTAssertTrue(operation.isConcurrent)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()

    wait(for: [expectation1], timeout: 4)

    XCTAssertTrue(operation.isCancelled)
  }

  func testEarlyBailOut() {
    let operation = AsynchronousBlockOperation<Void> { complete in complete(.success(())) }
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()

    wait(for: [expectation1], timeout: 4)

    XCTAssertTrue(operation.isCancelled)
  }

  func testBlockOperationCompletedInAsyncQueue() {
    let operation = AsynchronousBlockOperation<Void> { complete in
      XCTAssertTrue(Thread.isMainThread)
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 3) {
        complete(.success(()))
      }
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()

    wait(for: [expectation1], timeout: 4)
  }

  func testSuccessfulOutput() {
    let text = "Hello World"
    let operation = AsynchronousBlockOperation<String> { complete in
      complete(.success(text))
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [expectation1], timeout: 4)
    XCTAssertEqual(operation.output?.success, text)
    XCTAssertEqual(operation.name, "AsynchronousBlockOperation <String>")
  }

  func testFailedOutput() {
    let operation = AsynchronousBlockOperation<String> { complete in
      complete(.failure(MockError.failed))
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [expectation1], timeout: 4)
    XCTAssertNil(operation.output?.success)
    XCTAssertNotNil(operation.output?.failure)
  }

  func testBlockOperationCompletedWithErrorsInAsyncQueue() {
    let error = MockError.generic(date: Date())
    var object = NSObject()
    weak var weakObject = object

    autoreleasepool {
      var operation = AsynchronousBlockOperation<Void> { [weak object] complete in
        DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
          _ = object
          complete(.failure(error))
        }
      }

      let expectation1 = expectation(description: "\(#function)\(#line)")
      operation.addCompletionBlock { expectation1.fulfill() }
      operation.start()

      waitForExpectations(timeout: 5)
      XCTAssertTrue(operation.isFinished)

      if let opError = operation.output?.failure as? MockError {
        XCTAssertEqual(opError, error)
      } else {
        XCTFail("Wrong error type.")
      }

      // Memory leaks test: once release the operation, the captured object (by reference) should be nil (weakObject)
      operation = AsynchronousBlockOperation { .success(()) }
      object = NSObject()
    }
    XCTAssertNil(weakObject)
  }

  func testBlockOperationWithAnAsyncQueueInside() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    // The other AdvancedBlockOperation initializer will fail here becase we need a more fine control
    // on when the operation should be considered finished.
    let operation = AsynchronousBlockOperation<Void>() { complete in
      DispatchQueue.global().async {
        sleep(3)
        expectation1.fulfill()
        complete(.success(()))
      }
    }
    operation.addCompletionBlock {
      expectation2.fulfill()
    }
    operation.start()
    wait(for: [expectation1, expectation2], timeout: 10, enforceOrder: true)
  }

  func testBlockOperationWithDispatchQueue() {
    let queue = DispatchQueue(label: "\(identifier).\(#function)")
    let operation = AsynchronousBlockOperation(queue: queue) {
      XCTAssertFalse(Thread.isMainThread)
    }

    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    waitForExpectations(timeout: 3)
  }

  func testComposition() {
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()

    operation3.addCompletionBlock { expectation3.fulfill() }
    let adapterOperation = AsynchronousBlockOperation { [unowned operation2] in
      operation2.cancel()
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

  func testMemoryLeak() {
    var object = NSObject()
    weak var weakObject = object

    autoreleasepool {
      var operation = AsynchronousBlockOperation<Void> { [unowned object] complete in
        DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).async {
          _ = object
          complete(.success(()))
        }
      }

      let expectation1 = expectation(description: "\(#function)\(#line)")
      operation.addCompletionBlock { expectation1.fulfill() }
      operation.start()

      waitForExpectations(timeout: 3)

      // Memory leaks test: once the operation is released, the captured object (by reference) should be nil (weakObject)
      operation = AsynchronousBlockOperation(block: { })
      object = NSObject()
    }

    XCTAssertNil(weakObject, "Memory leak: the object should have been deallocated at this point.")
  }
}
