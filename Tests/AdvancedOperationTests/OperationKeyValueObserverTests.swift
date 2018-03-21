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

final class OperationKeyValueObserverTests: XCTestCase {

  func testStart() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
    let keyValueObserverControllerController = OperationObserverController(operation: operation)
    let observer = MockObserver()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    keyValueObserverControllerController.registerObserver(observer)
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()

    waitForExpectations(timeout: 6)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willExecutetCount, 1)
  }

  func testMultipleStart() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
    let keyValueObserverController = OperationObserverController(operation: operation)
    let observer = MockObserver()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    keyValueObserverController.registerObserver(observer)
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    operation.start()

    waitForExpectations(timeout: 6)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willExecutetCount, 1)
  }

  func testCancel() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
    let keyValueObserverController = OperationObserverController(operation: operation)
    let observer = MockObserver()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    keyValueObserverController.registerObserver(observer)
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    operation.cancel()

    waitForExpectations(timeout: 6)
    XCTAssertEqual(observer.didCancelCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willExecutetCount, 1)
  }

  func testCancelWithoutStart() {
    do {
      let operation = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
      let keyValueObserverController = OperationObserverController(operation: operation)
      let observer = MockObserver()
      let expectation1 = expectation(description: "\(#function)\(#line)")

      keyValueObserverController.registerObserver(observer)
      operation.addCompletionBlock { expectation1.fulfill() }
      operation.cancel()
      operation.cancel()
      operation.start()

      waitForExpectations(timeout: 6)
      XCTAssertEqual(observer.didCancelCount, 1)
      XCTAssertEqual(observer.didFinishCount, 1)
      XCTAssertEqual(observer.willExecutetCount, 0) // stopped, before execution
    }

    do {
      let operation = BlockOperation(block: { sleep(1) })
      let keyValueObserverController = OperationObserverController(operation: operation)
      let observer = MockObserver()
      let expectation1 = expectation(description: "\(#function)\(#line)")

      keyValueObserverController.registerObserver(observer)
      operation.addCompletionBlock { expectation1.fulfill() }
      operation.cancel()
      operation.cancel()
      operation.start()

      waitForExpectations(timeout: 6)
      XCTAssertEqual(observer.didCancelCount, 1)
      XCTAssertEqual(observer.didFinishCount, 1)
      XCTAssertEqual(observer.willExecutetCount, 0) // stopped, before execution
    }
  }

  func testMultipleCancel() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
    let keyValueObserverController = OperationObserverController(operation: operation)
    let observer = MockObserver()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    keyValueObserverController.registerObserver(observer)
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    operation.cancel()
    operation.cancel()

    waitForExpectations(timeout: 6)
    XCTAssertEqual(observer.didCancelCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willExecutetCount, 1)
  }

//  func testMemoryLeak() {
//    var operation: SleepyAsyncOperation? = SleepyAsyncOperation(interval1: 1, interval2: 3, interval3: 1)
//    weak var weakOperation = operation
//
//    var keyValueObserverController: OperationObserverController? = OperationObserverController(operation: operation!)
//    weak var weakObserverController = keyValueObserverController
//
//    let observer = MockObserver()
//    let expectation1 = expectation(description: "\(#function)\(#line)")
//
//    keyValueObserverController!.registerObserver(observer)
//    operation!.addCompletionBlock {
//      expectation1.fulfill()
//
//    }
//    operation!.start()
//    operation!.cancel()
//
//    waitForExpectations(timeout: 6)
//    XCTAssertEqual(observer.didCancelCount, 1)
//    XCTAssertEqual(observer.didFinishCount, 1)
//    XCTAssertEqual(observer.willExecutetCount, 1)
//
//    operation = nil
//    //XCTAssertNil(weakOperation) // TODO: fix this
//    keyValueObserverController = nil
//    XCTAssertNil(weakObserverController)
//    XCTAssertNil(weakOperation)
//  }

}
