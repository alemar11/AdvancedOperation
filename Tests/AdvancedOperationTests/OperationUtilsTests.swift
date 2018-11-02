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

final class OperationUtilsTests: XCTestCase {

  func testAddCompletionBlock() {
    let operation = SleepyOperation()
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
    let operation = SleepyOperation()
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
    let operation = SleepyOperation()
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

  func testThenOneToOne() {
    let operation1 = SleepyOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation1.addCompletionBlock { expectation1.fulfill() }

    let operation2 = SleepyOperation()
    let expectation2 = expectation(description: "\(#function)\(#line)")
    operation2.addCompletionBlock { expectation2.fulfill() }

    let operation3 = SleepyOperation()
    let expectation3 = expectation(description: "\(#function)\(#line)")
    operation3.addCompletionBlock { expectation3.fulfill() }

    operation1.then(operation2).then(operation3)

    let queue = AdvancedOperationQueue()
    queue.addOperations([operation2, operation1, operation3], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3], timeout: 30, enforceOrder: true)
  }

  func testThenOneToMany() {
    let operation1 = SleepyOperation()
    let operation2 = SleepyOperation()
    let operation3 = SleepyOperation()

    let expectation2 = expectation(description: "\(#function)\(#line)")
    operation2.addCompletionBlock { expectation2.fulfill() }
    let expectation3 = expectation(description: "\(#function)\(#line)")
    operation3.addCompletionBlock { expectation3.fulfill() }

    [operation1].then(operation3, operation2)

    let queue = AdvancedOperationQueue()
    queue.addOperations([operation2, operation1, operation3], waitUntilFinished: false)

    wait(for: [expectation2, expectation3], timeout: 30)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
  }

  func testThenManyToOne() {
    let operation1 = SleepyOperation()
    let operation2 = SleepyOperation()
    let operation3 = SleepyOperation()

    let expectation3 = expectation(description: "\(#function)\(#line)")
    operation3.addCompletionBlock { expectation3.fulfill() }

    [operation1, operation2].then(operation3)

    let queue = AdvancedOperationQueue()
    queue.addOperations([operation2, operation1, operation3], waitUntilFinished: false)

    wait(for: [expectation3], timeout: 30)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
  }

  func testThenManyToMany() {
    let operation1 = SleepyOperation()
    let operation2 = SleepyOperation()
    let operation3 = SleepyOperation()
    let operation4 = SleepyOperation()

    let expectation3 = expectation(description: "\(#function)\(#line)")
    operation3.addCompletionBlock { expectation3.fulfill() }
    let expectation4 = expectation(description: "\(#function)\(#line)")
    operation4.addCompletionBlock { expectation4.fulfill() }

    [operation1, operation2].then(operation3, operation4)

    let queue = AdvancedOperationQueue()
    queue.addOperations([operation2, operation1, operation3, operation4], waitUntilFinished: false)

    wait(for: [expectation3, expectation4], timeout: 30)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
    XCTAssertTrue(operation4.isFinished)
  }

  func testRemoveDependencies() {
    let operation1 = AdvancedBlockOperation(block: {})
    let operation2 = SleepyOperation()
    let operation3 = BlockOperation(block: {})
    let operation4 = SleepyAsyncOperation()

    operation4.addDependencies([operation1, operation2, operation3])
    XCTAssertEqual(operation4.dependencies.count, 3)

    operation4.removeDependencies()
    XCTAssertEqual(operation4.dependencies.count, 0)
  }

}
