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

final class DelayOperationTests: XCTestCase {
  func testInterval() {
    let start = Date()
    let operation = DelayOperation(interval: 2)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    operation.start()

    wait(for: [expectation1], timeout: 3)

    let seconds = Date().timeIntervalSince(start)
    XCTAssertEqual(seconds, 2, accuracy: 0.3)
  }

  func testDate() {
    let start = Date()
    let end = start.addingTimeInterval(2)
    let operation = DelayOperation(until: end)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    operation.start()

    wait(for: [expectation1], timeout: 3)

    let seconds = Date().timeIntervalSince(start)
    XCTAssertEqual(seconds, 2, accuracy: 0.3)

  }

  func testNegativeInterval() {
    let operation = DelayOperation(interval: -2)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)

    operation.start()

    wait(for: [expectation1], timeout: 3)

    XCTAssertFalse(operation.isCancelled)
  }

  func testCancel() {
    let start = Date()
    let end = start.addingTimeInterval(4)
    let operation = DelayOperation(until: end)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)

    operation.start()
    operation.cancel()

    wait(for: [expectation1], timeout: 10)

    let seconds = Date().timeIntervalSince(start)
    XCTAssertEqual(seconds, 4, accuracy: 0.3)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }

  func testCancelBeforeStart() {
    let start = Date()
    let operation = DelayOperation(interval: 2)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)

    operation.cancel()
    operation.start()

    wait(for: [expectation1], timeout: 3)

    let seconds = Date().timeIntervalSince(start)
    XCTAssertEqual(seconds, 0, accuracy: 0.3)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
}
