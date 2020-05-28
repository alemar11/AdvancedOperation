// 
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

final class ResultOperationTests: XCTestCase {
  func testCancelBeforeExecuting() {
    let operation = DummyResultOperation()
    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    operation.onResultProduced = { result in
      switch result {
      case .failure(let error) where error == .cancelled:
        resultProducedExpectation.fulfill()
      default:
        XCTFail("Expected a cancelled error.")
      }
    }
    operation.cancel()
    operation.start()
    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  }

//  func testFinishBeforeExecuting() {
//    let operation = DummyResultOperation()
//    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
//    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
//    operation.onResultProduced = { result in
//      switch result {
//      case .failure(let error) where error == .cancelled:
//        resultProducedExpectation.fulfill()
//      default:
//        XCTFail("Expected a cancelled error.")
//      }
//    }
//    //operation.cancel()
//    operation.finish()
//    operation.start()
//    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
//  }

  func testSuccessFulExecution() {
    let queue = OperationQueue()
    let operation = DummyResultOperation()
    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    operation.onResultProduced = { result in
      switch result {
      case .success(let value) where value == "Success":
        resultProducedExpectation.fulfill()
      default:
        XCTFail(#"Expected a "Success" value."#)
      }
    }
    queue.addOperation(operation)
    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  }
}
