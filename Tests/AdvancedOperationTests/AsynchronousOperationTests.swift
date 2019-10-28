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
//  func test_investigation() throws {
//    let operation = BlockOperation()
//      let expectation1 = XCTKVOExpectation(keyPath: #keyPath(BlockOperation.isFinished), object: operation, expectedValue: true)
//    operation.addExecutionBlock {
//      //DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//        print("1")
//      //}
//
//    }
//    operation.addExecutionBlock {
//      print("2")
//    }
//    operation.start()
//    wait(for: [expectation1], timeout: 10)
//    XCTAssertTrue(operation.isFinished)
//  }

  func testOutputBeforeStarting() throws {
     let operation = AsynchronousOperation<Any>.SleepyAsyncOperation()
    XCTAssertFalse(operation.isExecuting)

    // https://forums.swift.org/t/xctunwrap-not-available-during-swift-test/28878/4
    //let output = try XCTUnwrap(operation.output.failure) as NSError
    guard let output = operation.output.failure else {
      XCTFail("The operation should have a failure output")
      return
    }

    XCTAssertEqual(output as NSError, NSError.notStarted)
  }
    func testStart() {
      let operation = AsynchronousOperation<Any>.SleepyAsyncOperation() // by default is 3 second long
      let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
      XCTAssertTrue(operation.isReady)

      operation.start()
      XCTAssertTrue(operation.isExecuting)

      wait(for: [expectation1], timeout: 10)
      XCTAssertTrue(operation.isFinished)
    }

    func testCancel() {
      let operation = AsynchronousOperation<Any>.SleepyAsyncOperation()
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
      let operation = AsynchronousOperation<Any>.SleepyAsyncOperation()

      XCTAssertTrue(operation.isReady)
      let expectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isCancelled), object: operation, expectedValue: true)
      operation.cancel()

      wait(for: [expectation], timeout: 10)

      XCTAssertTrue(operation.isCancelled)
      XCTAssertFalse(operation.isFinished)
    }

    func testCancelBeforeStart() {
      let operation = AsynchronousOperation<Any>.SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
      XCTAssertTrue(operation.isReady)

      operation.cancel()
      operation.start()
      XCTAssertTrue(operation.isCancelled)

      operation.waitUntilFinished()

      XCTAssertTrue(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
    }

    func testMultipleCancel() {
      let operation = AsynchronousOperation<Any>.SleepyAsyncOperation()
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
      let operation = AsynchronousOperation<Any>.FailingAsyncOperation()
      let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

      operation.start()

      wait(for: [expectation1], timeout: 10)
      XCTAssertNotNil(operation.output.failure)
    }

    // The readiness of operations is determined by their dependencies on other operations and potentially by custom conditions that you define.
    func testReadiness() {
      // Given
      let operation1 = AsynchronousOperation<Any>.SleepyAsyncOperation()
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
}
