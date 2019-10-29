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

final class NegatedConditionTests: XCTestCase {
  func testNotFulFilledConditionWithoutOperationQueue() {
    let condition = BlockCondition { _ in .success(()) }
    let negatedCondition = NegatedCondition(condition: condition)
    let operation = SleepyAsyncOperation()
    operation.addCondition(negatedCondition)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()

    wait(for: [expectation1], timeout: 5)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertNotNil(operation.output.failure)
    XCTAssertTrue(operation.isFinished)
  }

  func testFulFilledConditionWithoutOperationQueue() {
    let condition = BlockCondition { _ in .failure(MockError.failed) }
    let negatedCondition = NegatedCondition(condition: condition).negated.negated
    let operation = SleepyAsyncOperation()
    operation.addCondition(negatedCondition)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()

     wait(for: [expectation1], timeout: 5)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertNotNil(operation.output.success)
    XCTAssertTrue(operation.isFinished)
  }

  func testNegationWithFailingCondition() {
    let negatedFailingCondition = NegatedCondition(condition: BlockCondition { _ in .failure(MockError.failed) })
    let dummyOperation = AdvancedBlockOperation { }
    let expectation1 = expectation(description: "\(#function)\(#line)")
    negatedFailingCondition.evaluate(for: dummyOperation) { (result) in
      switch result {
      case .success:
        expectation1.fulfill()
      default: return
      }
    }
    waitForExpectations(timeout: 2)
  }

  func testNegationWithSuccessingCondition() {
    let negatedCondition = NegatedCondition(condition: BlockCondition { _ in .success(()) })
    let dummyOperation = AdvancedBlockOperation { }
    let expectation1 = expectation(description: "\(#function)\(#line)")
    negatedCondition.evaluate(for: dummyOperation) { (result) in
      switch result {
      case .failure:
        expectation1.fulfill()
      default: return
      }
    }
    waitForExpectations(timeout: 2)
  }

  func testMutitpleNegatedConditions() {
    let queue = OperationQueue()

    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"

    let operation2 = CancellingAsyncOperation()
    operation2.name = "operation2"

    let operation3 = FailingAsyncOperation(error: .failed)
    operation3.name = "operation3"

    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"

    let operation5 = AdvancedBlockOperation { }
    operation5.name = "operation5"

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)
    let expectation5 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation5, expectedValue: true)

    // operation1 is executed only if there is at least one cancelled operation in its dependencies.
    operation1.addCondition(NoCancelledDependeciesCondition().negated)
    operation1.addCondition(BlockCondition { _ in .failure(MockError.failed)}.negated)
    operation1.addDependency(operation2)
    operation1.addDependency(operation3)
    operation1.addDependency(operation4)
    operation5.addDependency(operation2)
    // operation5 is executed only if there aren't cancelled dependencies.
    operation5.addCondition(NoCancelledDependeciesCondition().negated.negated)

    queue.addOperations([operation2, operation1, operation3, operation5, operation4], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10)

    XCTAssertNotNil(operation1.output.success)
    XCTAssertNotNil(operation5.output.failure)
  }
}
