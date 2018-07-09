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

class InjectionTests: XCTestCase {

  func testInputAndOutput() {
    let operation1 = IntToStringOperation()
    operation1.input = 10
    operation1.start()
    XCTAssertEqual(operation1.output, "10")

    let operation2 = StringToIntOperation()
    operation2.input = "10"
    operation2.start()
    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionWithWaitUntilFinishedUsingClassMethod() {
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    operation1.input = 10
    let adapterOperation = AdvancedOperation.injectOperation(operation1, into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionWithWaitUntilFinishedUsingInstanceMethod() {
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    operation1.input = 10
    let adapterOperation = operation1.inject(into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionWithoutWaitingUntileFinished() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    let operation3 = AdvancedBlockOperation {
      expectation.fulfill()
    }
    operation3.addDependency(operation2)

    operation1.input = 10
    let adapterOperation = AdvancedOperation.injectOperation(operation1, into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation, operation3], waitUntilFinished: false)

    waitForExpectations(timeout: 3)
    XCTAssertEqual(operation2.input, "10")
    XCTAssertEqual(operation2.output, 10)
  }

}
