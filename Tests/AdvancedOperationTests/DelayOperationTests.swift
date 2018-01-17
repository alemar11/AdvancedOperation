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

#if !os(Linux)

import XCTest
@testable import AdvancedOperation

class DelayOperationTests: XCTestCase {
  
  func testStandardFlow() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let start = Date()
    let operation = DelayOperation(interval: 2)

    operation.completionBlock = {
      let seconds = Date().timeIntervalSince(start)
      XCTAssertTrue(seconds > 2 && seconds < 3)
      exp.fulfill()
    }
    
    operation.start()
    waitForExpectations(timeout: 3)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testNegativeInterval() {
    let exp = expectation(description: "\(#function)\(#line)")
    let operation = DelayOperation(interval: -2)
    operation.completionBlock = { exp.fulfill() }
    
    operation.start()
    waitForExpectations(timeout: 3)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testBailingOutEarly() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let start = Date()
    let operation = DelayOperation(interval: 2)
    operation.completionBlock = {
      let seconds = Date().timeIntervalSince(start)
      XCTAssertTrue(seconds > 0 && seconds < 1)
      exp.fulfill()
    }
    
    operation.cancel()
    operation.start()
    waitForExpectations(timeout: 3)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
}

#endif
