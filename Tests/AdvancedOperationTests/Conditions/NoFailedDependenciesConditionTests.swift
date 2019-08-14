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

final class NoFailedDependenciesConditionTests: XCTestCase {
  func testEmptyMutuallyExclusiveCategories() {
    let condition = NoFailedDependenciesCondition()
    XCTAssertTrue(condition.mutuallyExclusiveCategories.isEmpty)
  }
  
  func testFinishedAndFailedOperation() {
    let queue = OperationQueue()
    
    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"
    
    let operation2 = FailingAsyncOperation(error: .failed)
    operation2.name = "operation2"
    
    let operation3 = SleepyAsyncOperation()
    operation3.name = "operation3"
    
    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    
    operation1.addCondition(NoFailedDependenciesCondition())
    operation1.addDependencies(operation4, operation3, operation2)
    
    XCTAssertFalse(operation1.isExecuting)
    XCTAssertFalse(operation2.isExecuting)
    XCTAssertFalse(operation3.isExecuting)
    XCTAssertFalse(operation4.isExecuting)
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    
    XCTAssertTrue(operation1.hasError)
  }
  
  func testCancelledAndFailedOperation() {
    let queue = OperationQueue()
    
    let operation1 = AdvancedBlockOperation { complete in complete(nil) }
    operation1.name = "operation1"
    
    let operation2 = AdvancedBlockOperation { complete in complete(nil) }
    operation2.name = "operation2"
    
    let operation3 = AdvancedBlockOperation { complete in complete(nil) }
    operation3.name = "operation3"
    
    let operation4 = AdvancedBlockOperation { complete in complete(nil) }
    operation4.name = "operation4"
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    
    operation2.cancel(error: MockError.failed)
    
    operation1.addCondition(NoFailedDependenciesCondition())
    operation1.addDependencies(operation4, operation3, operation2)
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    
    XCTAssertTrue(operation1.hasError)
    XCTAssertTrue(operation2.isCancelled)
  }
  
  func testCancelledAndFailedOperationWaitUntilFinished() {
    let queue = OperationQueue()
    
    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"
    
    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    operation2.name = "operation2"
    
    let operation3 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    operation3.name = "operation3"
    
    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"
    
    operation2.cancel(error: MockError.failed)
    
    operation1.addCondition(NoFailedDependenciesCondition())
    operation1.addDependencies(operation4, operation3, operation2)
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    
    XCTAssertTrue(operation1.hasError)
  }
  
  func testIgnoredCancelledAndFailedOperation() {
    let queue = OperationQueue()
    
    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"
    
    let operation2 = AdvancedBlockOperation { }
    operation2.name = "operation2"
    
    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"
    
    let operation4 = AdvancedBlockOperation { }
    operation4.name = "operation4"
    
    operation2.cancel(error: MockError.failed)
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    
    operation1.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))
    operation1.addDependencies(operation4, operation3, operation2)
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    XCTAssertFalse(operation1.hasError)
  }
  
  func testIgnoredCancelledAndFailedOperations() {
    let queue = OperationQueue()
    
    let operation1 = NotExecutableOperation()
    operation1.name = "operation1"
    
    let operation2 = AdvancedBlockOperation { }
    operation2.name = "operation2"
    
    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"
    
    let operation4 = FailingAsyncOperation(error: .failed)
    operation4.name = "operation4"
    
    operation2.cancel(error: MockError.failed)
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    
    operation1.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))
    operation1.addDependencies(operation4, operation3, operation2)
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    
    XCTAssertTrue(operation1.hasError)
  }
  
  func testFinishedAndFailedOperationNegated() {
    let queue = OperationQueue()
    
    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"
    
    let operation2 = FailingAsyncOperation(error: .failed)
    operation2.name = "operation2"
    
    let operation3 = AdvancedBlockOperation { }
    operation3.name = "operation3"
    
    let operation4 = AdvancedBlockOperation { }
    operation4.name = "operation4"
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    
    operation1.addCondition(NegatedCondition(condition: NoFailedDependenciesCondition()))
    operation1.addDependencies(operation4, operation3, operation2)

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    
    XCTAssertFalse(operation1.hasError)
  }
}
