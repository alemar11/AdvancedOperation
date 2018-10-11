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

class TimeoutObserverTests: XCTestCase {

    func testOperationCancelledByTheTimeoutObserver() {
      let expectation = self.expectation(description: "\(#function)\(#line)")
      let operation = SleepyAsyncOperation(interval1: 5, interval2: 1, interval3: 1)
      operation.name = "operation"
      operation.addCompletionBlock {
        expectation.fulfill()
      }
      operation.addObserver(TimeoutObserver(timeout: 3))
      operation.start()
      waitForExpectations(timeout: 7) // The SleepyAsyncOperation will check the cancelled state after each interval (so 0, 5, 1, 1)
      XCTAssertTrue(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
      XCTAssertTrue(operation.isFailed)
    }

  func testSuccessfullOperation() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    operation.name = "operation"
    operation.addCompletionBlock {
      expectation.fulfill()
    }
    operation.addObserver(TimeoutObserver(timeout: 5))
    operation.start()
    waitForExpectations(timeout: 7) // The SleepyAsyncOperation will check the cancelled state after each interval (so 0, 1, 1, 1)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isFailed)
  }

}
