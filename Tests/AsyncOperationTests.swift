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

class AsyncOperationTests: XCTestCase {

  private class SleepyOperation: AsyncOperation {

    override func execute() {
      DispatchQueue.global().async { [weak weakSelf = self] in
        guard let strongSelf = weakSelf else { return self.finish() }

        if strongSelf.isCancelled { strongSelf.finish() }
        sleep(2)
        if strongSelf.isCancelled { strongSelf.finish() }
        sleep(3)

        strongSelf.finish()
      }

    }

  }

    func testStandardFlow() {
      let exp = expectation(description: "\(#function)\(#line)")
      let operation = SleepyOperation()
      operation.completionBlock = { exp.fulfill() }

      XCTAssertTrue(operation.isReady)
      XCTAssertFalse(operation.isExecuting)
      XCTAssertFalse(operation.isCancelled)
      XCTAssertFalse(operation.isFinished)

      operation.start()
      XCTAssertFalse(operation.isReady)
      XCTAssertTrue(operation.isExecuting)
      XCTAssertFalse(operation.isCancelled)
      XCTAssertFalse(operation.isFinished)

      operation.cancel()
      XCTAssertFalse(operation.isReady)
      XCTAssertTrue(operation.isCancelled)
      sleep(3)
      XCTAssertTrue(operation.isFinished)
      XCTAssertFalse(operation.isExecuting)

      wait(for: [exp], timeout: 10)
      //waitForExpectations(timeout: 10, handler: nil)
    }

  func testBailingOutEarly() {
    let exp = expectation(description: "\(#function)\(#line)")
    let operation = SleepyOperation()
    operation.completionBlock = { exp.fulfill() }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.cancel()

    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)

    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    sleep(3)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)

    wait(for: [exp], timeout: 10)
    //waitForExpectations(timeout: 10, handler: nil)
  }



}
