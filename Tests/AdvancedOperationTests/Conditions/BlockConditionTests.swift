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

class BlockConditionTests: XCTestCase {

  func testFailedCondition() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)
    let condition = BlockCondition { () -> Bool in
      return false
    }

    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)
    queue.addOperations([operation], waitUntilFinished: true)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.hasErrors)
    XCTAssertTrue(operation.isFinished)
  }

  func testStress() {
    (1...100).forEach { (i) in
      print(i)
      testFailedConditionAfterAThrowedError()
      print("\n")
    }
  }

  func testFailedConditionAfterAThrowedError() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)
    let condition = BlockCondition { () -> Bool in
      throw MockError.failed
    }

    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)

    operation.name = "Operation"
    operation.useOSLog(TestsLog)

    queue.addOperations([operation], waitUntilFinished: true)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.hasErrors)
    XCTAssertTrue(operation.isFinished)
  }

  func testSuccessfulCondition() {
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)
    let condition = BlockCondition { () -> Bool in
      return true
    }

    let operation = SleepyAsyncOperation()
    operation.addCondition(condition)
    queue.addOperations([operation], waitUntilFinished: true)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.hasErrors)
    XCTAssertTrue(operation.isFinished)
  }

}
