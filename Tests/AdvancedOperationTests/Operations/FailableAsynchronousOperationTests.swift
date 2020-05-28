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

final class FailableAsynchronousOperationTests: XCTestCase {
  func testCancelBeforeExecuting() {
    let operation = DummyFailableOperation(shouldFail: true)
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertEqual(operation.error, DummyFailableOperation.Error.cancelled)
  }

//  func testFinishBeforeExecuting() {
//    let operation = DummyFailableOperation(shouldFail: false)
//    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
//    //operation.cancel()
//    operation.finish() // ⚠️ finish() must not for any reason called outside the main() scope
//    wait(for: [finishExpectation], timeout: 2)
//  }

  func testSuccessFulExecution() {
    let queue = OperationQueue()
    let operation = DummyFailableOperation(shouldFail: false)
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertNil(operation.error)
  }

  func testFailedExecution() {
    let queue = OperationQueue()
    let operation = DummyFailableOperation(shouldFail: true)
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertEqual(operation.error, DummyFailableOperation.Error.operationFailed)
  }
}
