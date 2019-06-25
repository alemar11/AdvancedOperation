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
    let operation = AdvancedBlockOperation { complete in
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        complete([])
      }
    }
    XCTAssertTrue(operation.isAsynchronous)
    XCTAssertTrue(operation.isConcurrent)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    operation.start()
    operation.cancel()

    wait(for: [expectation1], timeout: 4)

    XCTAssertTrue(operation.isCancelled)
  }

  func testEarlyBailOut() {
    let operation = AdvancedBlockOperation { complete in
      complete([])
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()

    wait(for: [expectation1], timeout: 4)

    XCTAssertTrue(operation.isCancelled)
  }

  func testBlockOperationWithAsyncQueue() {
    let operation = AdvancedBlockOperation { complete in
      XCTAssertTrue(Thread.isMainThread)
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 3) {
        complete([])
      }
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    operation.start()

    wait(for: [expectation1], timeout: 4)

  }

  func testBlockOperationWithAsyncQueueFinishedWithErrors () {
    let errors = [MockError.generic(date: Date()), MockError.failed]

    var object = NSObject()
    weak var weakObject = object

    var operation = AdvancedBlockOperation { [object] complete in
      DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).asyncAfter(deadline: .now() + 2) {
        _ = object
        complete(errors)
      }
    }

    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()

    waitForExpectations(timeout: 5)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: errors)

    // Memory leaks test: once release the operation, the captured object (by reference) should be nil (weakObject)
    operation = AdvancedBlockOperation { }
    object = NSObject()
    XCTAssertNil(weakObject)
  }

  func testBlockOperationWithDispatchQueue() {
    let queue = DispatchQueue(label: "\(identifier).\(#function)")
    let operation = AdvancedBlockOperation(queue: queue) {
      XCTAssertFalse(Thread.isMainThread)
    }

    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    waitForExpectations(timeout: 3)
  }

  func testComposition() {
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyOperation()

    operation3.addCompletionBlock { expectation3.fulfill() }
    let adapterOperation = AdvancedBlockOperation { [unowned operation2] in
      operation2.cancel()
    }
    operation1.then(adapterOperation).then(operation2).then(operation3)
    let queue = AdvancedOperationQueue()

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
      var operation = AdvancedBlockOperation { [unowned object] complete in
        DispatchQueue(label: "\(identifier).\(#function)", attributes: .concurrent).async {
          _ = object
          complete([])
        }
      }

      let expectation1 = expectation(description: "\(#function)\(#line)")
      operation.addCompletionBlock { expectation1.fulfill() }
      operation.start()

      waitForExpectations(timeout: 3)

      // Memory leaks test: once the operation is released, the captured object (by reference) should be nil (weakObject)
      operation = AdvancedBlockOperation(block: { })
      object = NSObject()
    }

    XCTAssertNil(weakObject)
  }
}
