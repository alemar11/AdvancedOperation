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

class AdvancedOperationErrorTests: XCTestCase {

  func testConditionFailedError() {
    let message = "test"
    let info = ["1":1, "a": "a"] as [String : Any]
    let error = AdvancedOperationError.conditionFailed(message: message, userInfo: info)

    XCTAssertEqual(error.domain, identifier)
    XCTAssertEqual(error.code, 100)
    XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, message)
    XCTAssertEqual(error.userInfo["1"] as! Int, 1)
    XCTAssertEqual(error.userInfo["a"] as! String, "a")
  }

  func testExecutionCancelledError() {
    let message = "test"
    let info = ["1":1, "a": "a"] as [String : Any]
    let error = AdvancedOperationError.executionCancelled(message: message, userInfo: info)

    XCTAssertEqual(error.domain, identifier)
    XCTAssertEqual(error.code, 200)
    XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, message)
    XCTAssertEqual(error.userInfo["1"] as! Int, 1)
    XCTAssertEqual(error.userInfo["a"] as! String, "a")
  }

  func testExecutionFinishedError() {
    let message = "test"
    let info = ["1":1, "a": "a"] as [String : Any]
    let error = AdvancedOperationError.executionFinished(message: message, userInfo: info)

    XCTAssertEqual(error.domain, identifier)
    XCTAssertEqual(error.code, 300)
    XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, message)
    XCTAssertEqual(error.userInfo["1"] as! Int, 1)
    XCTAssertEqual(error.userInfo["a"] as! String, "a")
  }

}
