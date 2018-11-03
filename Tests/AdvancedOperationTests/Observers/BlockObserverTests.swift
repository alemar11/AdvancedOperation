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

class BlockObserverTests: XCTestCase {

  func testOperationProduced() {

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    let expectation6 = expectation(description: "\(#function)\(#line)")
    let expectation7 = expectation(description: "\(#function)\(#line)")

    expectation3.isInverted = true
    expectation4.isInverted = true
    var count = 0

    let observer = BlockObserver(willExecute: { (operation) in
      expectation1.fulfill()
    }, didProduce: { (operation, producedOperation) in
      count += 1
      if count == 2 {
        expectation2.fulfill()
      }
    }, willCancel: { (operation, errors) in
      expectation3.fulfill()

    }, didCancel: { (operation, errors) in
      expectation4.fulfill()

    }, willFinish: { (operation, errors) in
      expectation5.fulfill()

    }) { (operation, errors) in
      expectation6.fulfill()
    }
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer)

    operation.completionBlock = { expectation7.fulfill() }
    operation.produceOperation(BlockOperation { })
    operation.produceOperation(BlockOperation { })
    operation.start()

    waitForExpectations(timeout: 10)
  }

}
