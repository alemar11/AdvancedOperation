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

class GroupOperationTests: XCTestCase {
  
  func testFlow() {
    let exp1 = expectation(description: "\(#function)\(#line)")
    let operationOne = SleepyAsyncOperation()
    operationOne.addCompletionBlock { exp1.fulfill() }
    
    let exp2 = expectation(description: "\(#function)\(#line)")
    let operationTwo =  BlockOperation(block: { sleep(1)})
    operationTwo.addCompletionBlock { exp2.fulfill() }
    
    let exp3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operationOne, operationTwo)
    group.addCompletionBlock { exp3.fulfill() }
    
    group.start()
    wait(for: [exp1, exp2, exp3], timeout: 10)
    
    XCTAssertFalse(group.isExecuting)
    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)
  }
  
  func testOneOperationCancelled() {
    print("🚩🚩🚩🚩🚩🚩🚩🚩🚩🚩")
    let exp1 = expectation(description: "\(#function)\(#line)")
    let operationOne = SleepyAsyncOperation()
    operationOne.addCompletionBlock { exp1.fulfill() }
    
    let exp2 = expectation(description: "\(#function)\(#line)")
    let operationTwo =  BlockOperation(block: { sleep(1)})
    operationTwo.addCompletionBlock { exp2.fulfill() }
    
    let exp3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operationOne, operationTwo)
    group.addCompletionBlock {
      exp3.fulfill()
    }
   
    group.start()
    operationOne.cancel(error: MockError.test)
    wait(for: [exp1, exp2, exp3], timeout: 10)
    
    XCTAssertFalse(operationOne.isExecuting)
    XCTAssertTrue(operationOne.isCancelled)
     XCTAssertTrue(operationOne.isFinished)
    
    XCTAssertFalse(operationTwo.isExecuting)
    XCTAssertFalse(operationTwo.isCancelled)
    XCTAssertTrue(operationTwo.isFinished)
    
    XCTAssertFalse(group.isExecuting)
    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertEqual(group.aggregatedErrors.count, 1) //it seems that sometimes the wait finishes before che operationDidPerform callback
    XCTAssertEqual(group.errors.count, 1)
     print("🚩🚩🚩🚩🚩🚩🚩🚩🚩🚩")
  }
  
  func testGroupOperationCancelled() {
    let exp1 = expectation(description: "\(#function)\(#line)")
    let operation1 =  BlockOperation(block: { sleep(2)})
    operation1.addCompletionBlock { exp1.fulfill() }
    
    let exp2 = expectation(description: "\(#function)\(#line)")
    let operation2 =  BlockOperation(block: { sleep(2)})
    operation2.addCompletionBlock { exp2.fulfill() }
    
    let exp3 = expectation(description: "\(#function)\(#line)")
    let operation3 =  BlockOperation(block: { sleep(2)})
    operation3.addCompletionBlock { exp3.fulfill() }
    
    let exp4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.addCompletionBlock { exp4.fulfill() }
    
    group.start()
    group.cancel()
    
    wait(for: [exp1, exp2, exp3, exp4], timeout: 6)
    
    for operation in [operation1, operation2, operation3, group] {
      XCTAssertFalse(operation.isExecuting)
      XCTAssertTrue(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
      if let advancedOperation = operation as? AdvancedOperation {
        XCTAssertEqual(advancedOperation.errors.count, 0)
      }
    }
  }
  
  func testGroupOperationCancelledWithError() {
    let exp1 = expectation(description: "\(#function)\(#line)")
    let operation1 =  BlockOperation(block: { sleep(2)})
    operation1.addCompletionBlock { exp1.fulfill() }
    
    let exp2 = expectation(description: "\(#function)\(#line)")
    let operation2 =  BlockOperation(block: { sleep(2)})
    operation2.addCompletionBlock { exp2.fulfill() }
    
    let exp3 = expectation(description: "\(#function)\(#line)")
    let operation3 =  BlockOperation(block: { sleep(2)})
    operation3.addCompletionBlock { exp3.fulfill() }
    
    let exp4 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operation1, operation2, operation3)
    group.addCompletionBlock { exp4.fulfill() }
    
    group.start()
    group.cancel(error: MockError.test)
    
    wait(for: [exp1, exp2, exp3, exp4], timeout: 6)
    
    for operation in [operation1, operation2, operation3, group] {
      XCTAssertFalse(operation.isExecuting)
      XCTAssertTrue(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
      if let groupOperation = operation as? GroupOperation {
        XCTAssertEqual(groupOperation.errors.count, 1)
        XCTAssertEqual(groupOperation.aggregatedErrors.count, 0)
      } else if let advancedOperation = operation as? AdvancedOperation {
        XCTAssertEqual(advancedOperation.errors.count, 0)
      }
    }
  }
  
  func testGroupOperationWaitUntilFinished() {
    let operation1 =  BlockOperation(block: { sleep(2)})
    let operation2 =  BlockOperation(block: { sleep(2)})
    let operation3 =  BlockOperation(block: { sleep(2)})
    let group = GroupOperation(operations: operation1, operation2, operation3)
    
    group.start()
    group.waitUntilFinished()
    
    for operation in [operation1, operation2, operation3, group] {
      XCTAssertFalse(operation.isExecuting)
      XCTAssertFalse(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
      if let advancedOperation = operation as? AdvancedOperation {
        XCTAssertEqual(advancedOperation.errors.count, 0)
      } else if let groupOperation = operation as? GroupOperation {
        XCTAssertEqual(groupOperation.aggregatedErrors.count, 0)
      }
    }
  }
  
}
