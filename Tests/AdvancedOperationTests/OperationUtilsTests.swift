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

final class OperationUtilsTests: XCTestCase {
  func testAddCompletionBlock() {
    let operation = SleepyAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    operation.completionBlock = {
      expectation1.fulfill()
    }

    operation.addCompletionBlock(asEndingBlock: false) {
      expectation2.fulfill()
    }

    operation.start()
    wait(for: [expectation2, expectation1], timeout: 10, enforceOrder: true)
  }

  func testAddMultipleCompletionBlock() {
    let operation = SleepyAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    operation.completionBlock = {
      expectation1.fulfill()
    }

    operation.addCompletionBlock(asEndingBlock: false) {
      expectation2.fulfill()
    }

    operation.addCompletionBlock(asEndingBlock: false) {
      expectation3.fulfill()
    }

    operation.start()
    wait(for: [expectation3, expectation2, expectation1], timeout: 10, enforceOrder: true)
  }

  func testAddCompletionBlockWhileExecuting() {
    let operation = SleepyAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    operation.start()
    operation.addCompletionBlock {
      expectation1.fulfill()
    }
    waitForExpectations(timeout: 10)
  }

  func testAddCompletionBlockAsEndingBlock() {
    let operation = SleepyAsyncOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    var blockExecuted = false

    operation.completionBlock = {
      blockExecuted = true
    }

    operation.addCompletionBlock {
      XCTAssertTrue(blockExecuted)
      expectation1.fulfill()
    }
    operation.start()
    waitForExpectations(timeout: 10)
  }

  func testRemoveDependencies() {
    let operation1 = AsynchronousBlockOperation(block: { })
    let operation2 = SleepyAsyncOperation()
    let operation3 = BlockOperation { }
    let operation4 = SleepyAsyncOperation()

    operation4.addDependencies([operation1, operation2, operation3])
    XCTAssertEqual(operation4.dependencies.count, 3)

    operation4.removeDependencies()
    XCTAssertEqual(operation4.dependencies.count, 0)
  }

  func testHasSomeDependenciesCancelled() {
    let operation1 = BlockOperation()
    let operation2 = BlockOperation()
    let operation3 = BlockOperation()
    let operation4 = BlockOperation()

    operation4.addDependencies(operation1, operation2, operation3)
    XCTAssertFalse(operation4.hasSomeCancelledDependencies)

    operation1.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)

    operation2.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)

    operation2.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)
  }

  func testAddDepedenciesToMultipleOperationsAllTogether() {
    let operation1 = BlockOperation()
    let operation2 = BlockOperation()
    let operation3 = BlockOperation()
    let operation4 = BlockOperation()

    let sequence = [operation1, operation2, operation3, operation4]

    let operation5 = BlockOperation()
    let operation6 = BlockOperation()
    let operation7 = BlockOperation()
    let operation8 = BlockOperation()

    sequence.addDependencies(operation5, operation6, operation7)

    sequence.forEach {
      XCTAssertTrue($0.dependencies.contains(operation5))
      XCTAssertTrue($0.dependencies.contains(operation6))
      XCTAssertTrue($0.dependencies.contains(operation7))
      XCTAssertTrue($0.dependencies.contains(operation7))
      XCTAssertFalse($0.dependencies.contains(operation8))
    }
  }
}
