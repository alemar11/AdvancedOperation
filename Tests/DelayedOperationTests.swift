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

class DelayedOperationTests: XCTestCase {
  
  func testStandardFlow() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let start = Date()
    
    let operation = DelayedOperation(interval: 2) {
      let seconds = Date().timeIntervalSince(start)
      XCTAssertTrue(seconds > 2 && seconds < 3)
    }
    
    operation.completionBlock = { exp.fulfill() }
    
    operation.start()
    wait(for: [exp], timeout: 3)
  }
  
  func testNegativeInterval() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = DelayedOperation(interval: -2) { XCTFail("Negative interval: the block shouldn't be executed.") }
    operation.completionBlock = { exp.fulfill() }
    
    operation.start()
    wait(for: [exp], timeout: 3)
  }
  
  func testBailingOutEarly() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = DelayedOperation(interval: 2) { XCTFail("Cancelled operation: the block shouldn't be executed.") }
    operation.completionBlock = { exp.fulfill() }
    
    operation.cancel()
    operation.start()
    wait(for: [exp], timeout: 3)
  }
  
}
