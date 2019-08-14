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

final class BlockConditionTests: XCTestCase {
  func testEmptyMutuallyExclusiveCategories() {
    let condition = BlockCondition { false }
    XCTAssertTrue(condition.mutuallyExclusiveCategories.isEmpty)
  }
  
  func testFailedCondition() {
    let queue = OperationQueue()
    let condition = BlockCondition { false }
    
    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)
    operation.name = "operation"
    operation.log = TestsLog
    
    queue.addOperations([operation], waitUntilFinished: true)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.hasError)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testFailedConditionAfterAThrowedError() {
    let queue = OperationQueue()
    let condition = BlockCondition { () -> Bool in
      throw MockError.failed
    }
    
    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)
    
    operation.name = "Operation"
    operation.log = TestsLog
    
    queue.addOperations([operation], waitUntilFinished: true)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.hasError)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testSuccessfulCondition() {
    let queue = OperationQueue()
    let condition = BlockCondition { () -> Bool in
      return true
    }
    
    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)
    queue.addOperations([operation], waitUntilFinished: true)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.hasError)
    XCTAssertTrue(operation.isFinished)
  }
}
