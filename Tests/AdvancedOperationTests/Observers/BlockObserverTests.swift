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

final class BlockObserverTests: XCTestCase {
  func testProducedOperationFlow() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    let expectation6 = expectation(description: "\(#function)\(#line)")
    let expectation7 = expectation(description: "\(#function)\(#line)")

    let producedOperation = BlockOperation { }
    let producer = ProducingOperationsOperation.OperationProducer(producedOperation, true, 0)
    let operation = ProducingOperationsOperation(operationProducers: [producer])
    operation.addCompletionBlock { expectation7.fulfill() }

    expectation3.isInverted = true
    expectation4.isInverted = true

    let observer = BlockObserver(willExecute: { (operation) in
      expectation1.fulfill()
    }, didProduce: { (operation, producedOperation) in
        expectation2.fulfill()
    }, willCancel: { (operation, errors) in
      expectation3.fulfill()

    }, didCancel: { (operation, errors) in
      expectation4.fulfill()

    }, willFinish: { (operation, errors) in
      expectation5.fulfill()

    }, didFinish: { (operation, errors) in
      expectation6.fulfill()
    })


      operation.addObserver(observer)
      queue.addOperation(operation)
//    queue.addOperation(producingOperation)
//    producingOperation.completionBlock = { expectation7.fulfill() }
//    producingOperation.produceOperation(BlockOperation { })
//    producingOperation.produceOperation(BlockOperation { })


    waitForExpectations(timeout: 10)
  }

  func testProducedOperationDependingFromTheProducingOperationOnConcurrentQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let producedOperation = AdvancedBlockOperation { do { } }
    producedOperation.log = TestsLog
    producedOperation.addCompletionBlock { expectation2.fulfill() }

    let producer = ProducingOperationsOperation.OperationProducer(producedOperation, false, 0)
    let operation = ProducingOperationsOperation(operationProducers: [producer])
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.log = TestsLog
    queue.addOperation(operation)

    // producedOperation will be executed only after the operation is done
    wait(for: [expectation1, expectation2], timeout: 15, enforceOrder: true)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(producedOperation.isFinished)
  }

  func testProducedOperationOnConcurrentQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 10
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let producedOperation = AdvancedBlockOperation { do { } }
    producedOperation.log = TestsLog
    producedOperation.addCompletionBlock { expectation2.fulfill() }

    let producer = ProducingOperationsOperation.OperationProducer(producedOperation, true, 5)
    let operation = ProducingOperationsOperation(operationProducers: [producer])
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.log = TestsLog
    queue.addOperation(operation)

    // producedOperation will be executed right after it gets produced
    wait(for: [expectation2, expectation1], timeout: 15, enforceOrder: true)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(producedOperation.isFinished)
  }

//  func testProducedOperationWithFailingConditionsOnConcurrentQueue() {
//    let queue = DispatchQueue(label: "\(#function)")
//    queue.sync {
//      let queue = OperationQueue()
//      queue.maxConcurrentOperationCount = 10
//      let expectation1 = expectation(description: "\(#function)\(#line)")
//      let expectation2 = expectation(description: "\(#function)\(#line)")
//
//      let producedOperation = AdvancedBlockOperation { do { } }
//      producedOperation.log = TestsLog
//      producedOperation.addCompletionBlock { expectation2.fulfill() }
//      producedOperation.addCondition(BlockCondition { false })
//
//      let producer = ProducingOperationsOperation.OperationProducer(producedOperation, true, 5)
//      let operation = ProducingOperationsOperation(operationProducers: [producer])
//      operation.addCompletionBlock { expectation1.fulfill() }
//      operation.log = TestsLog
//      queue.addOperation(operation)
//
//      // producedOperation will be executed right after it gets produced but it will have errors because of the condition
//      wait(for: [expectation2, expectation1], timeout: 15, enforceOrder: true)
//
//      XCTAssertTrue(producedOperation.hasError)
//      XCTAssertFalse(operation.hasError)
//      XCTAssertTrue(operation.isFinished)
//      XCTAssertTrue(producedOperation.isFinished)
//    }
//  }
}
