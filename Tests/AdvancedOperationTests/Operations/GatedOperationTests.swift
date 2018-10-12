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
import Foundation
@testable import AdvancedOperation

final class GatedOperationTests: XCTestCase {

  func testOpenedGate() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let gateOperation = GatedOperation(operation) { () -> Bool in
      return true
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: gateOperation, expectedValue: true)

    gateOperation.start()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(gateOperation.isCancelled)
  }

  func testOpenedGateAndCancelledOperation() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let gateOperation = GatedOperation(operation) { () -> Bool in
      return true
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: gateOperation, expectedValue: true)

    gateOperation.start()
    gateOperation.cancel()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(gateOperation.isCancelled)
  }

  func testOpenedGateUsingAdvancedOperationQueue() {
    let queue = AdvancedOperationQueue()
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let gateOperation = GatedOperation(operation) { () -> Bool in
      return true
    }

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: gateOperation, expectedValue: true)

    queue.addOperation(gateOperation)
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(gateOperation.isCancelled)
  }

  func testClosedGate() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let gateOperation = GatedOperation(operation) { () -> Bool in
      return false
    }

    gateOperation.useOSLog(TestsLog)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: gateOperation, expectedValue: true)

    gateOperation.start()
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation.isFailed)
    XCTAssertTrue(gateOperation.isFailed)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(gateOperation.isCancelled)
  }

  func testClosedGateUsingAdvancedOperationQueue() {
    let queue = AdvancedOperationQueue()
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let gateOperation = GatedOperation(operation) { () -> Bool in
      return false
    }

    gateOperation.useOSLog(TestsLog)

    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: gateOperation, expectedValue: true)

    queue.addOperation(gateOperation)
    wait(for: [expectation1, expectation2], timeout: 10)

    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFailed)
    XCTAssertFalse(operation.isFinished) // cancelled before executing
    XCTAssertTrue(gateOperation.isCancelled)
  }

  func testMixingGatedOperationWithDependencies() {
    let queue = AdvancedOperationQueue()
    //TODO: https://stackoverflow.com/questions/48137896/operation-went-isfinished-yes-without-being-started-by-the-queue-it-is-in
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = SleepyAsyncOperation()
    let operation4 = DelayOperation(interval: 1)

    let gateOperation3 = GatedOperation(operation3) { () -> Bool in
      return false
    }

    gateOperation3.addDependency(operation1)
    operation2.addDependency(operation1)

    operation4.addDependency(gateOperation3)
    operation4.addDependency(operation2)

    operation4.addCondition(NoCancelledDependeciesCondition())

    queue.addOperations([operation1, operation2, gateOperation3, operation4], waitUntilFinished: true)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertFalse(operation1.isFailed)

    XCTAssertTrue(operation2.isFinished)
    XCTAssertFalse(operation2.isFailed)

    XCTAssertTrue(gateOperation3.isFinished)
    XCTAssertTrue(gateOperation3.isFailed)
    XCTAssertTrue(gateOperation3.isCancelled)

    XCTAssertTrue(operation4.isFinished)
    XCTAssertTrue(operation4.isFailed)
    XCTAssertTrue(operation4.isCancelled)
  }

}
