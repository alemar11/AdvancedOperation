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

extension OperationUtilsTests {

  static var allTests = [
    ("testAddCompletionBlock", testAddCompletionBlock),
    ("testAddCompletionBlockAsEndingBlock", testAddCompletionBlockAsEndingBlock)
  ]

}

class OperationUtilsTests: XCTestCase {

  func testAddCompletionBlock() {
    let operation = SleepyOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")

    var blockExecuted = false

    operation.completionBlock = {
      blockExecuted = true
    }

    operation.addCompletionBlock(asEndingBlock: false) {
      XCTAssertFalse(blockExecuted)
      expectation1.fulfill()
    }
    operation.start()
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

}
