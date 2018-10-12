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

final class WrappedOperationTests: XCTestCase {

  func testWrappedAdvancedOperationCancelled() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let wrapped = WrappedOperation(operation: operation)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: wrapped, expectedValue: true)
    wrapped.start()
    wrapped.cancel()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(wrapped.isCancelled)
  }

  func testWrappedOperationCancelled() {
    let operation = BlockOperation { }
    let wrapped = WrappedOperation(operation: operation)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: wrapped, expectedValue: true)
    wrapped.start()
    wrapped.cancel()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(wrapped.isCancelled)
  }

  func testWrappedAdvancedOperationSuccessfull() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let wrapped = WrappedOperation(operation: operation)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: wrapped, expectedValue: true)
    wrapped.start()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(wrapped.isCancelled)
  }

  func testWrappedOperationSuccessful() {
    let operation = BlockOperation { }
    let wrapped = WrappedOperation(operation: operation)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: wrapped, expectedValue: true)
    wrapped.start()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(wrapped.isCancelled)
  }

}
