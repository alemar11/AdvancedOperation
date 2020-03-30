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

class AsynchronousResultOperationTests: XCTestCase {
  override class func setUp() {
    #if swift(<5.1)
    AdvancedOperation.KVOCrashWorkaround.installFix()
    #endif
  }

  func testSuccess() {
    let operation = IntToStringAsyncResultOperation()
    operation.input = 10
    let finishedExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [finishedExpectation], timeout: 5, enforceOrder: true)
    XCTAssertNotNil(operation.result)
    XCTAssertNoThrow(try operation.result.get())
  }

  func testFailure() {
    let operation = IntToStringAsyncResultOperation()
    let resultProducedExpectation = self.expectation(description: "Result produced")
    operation.input = -10
    operation.onResultProduced = { output in
      switch output {
      case .failure(let error):
        XCTAssertEqual(error, .invalidInput)
      default:
        XCTFail("The operation should have failed.")
      }
      resultProducedExpectation.fulfill()
    }
    let finishedExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [resultProducedExpectation, finishedExpectation], timeout: 5, enforceOrder: true)
    XCTAssertNotNil(operation.result)
    XCTAssertThrowsError(try operation.result.get(), "The operation result should contain an error.") { (error) in
      if let opError = error as? IntToStringAsyncResultOperation.Error {
        XCTAssertEqual(opError, .invalidInput)
      } else {
        XCTFail("Wrong error type")
      }
    }
  }

  func testCancelledExecutionBeforeStart() {
    let operation = IntToStringAsyncResultOperation()
    let resultProducedExpectation = self.expectation(description: "Result produced")
    resultProducedExpectation.isInverted = true
    operation.input = -10
    operation.onResultProduced = { output in
      resultProducedExpectation.fulfill()
    }
    let finishedExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [resultProducedExpectation, finishedExpectation], timeout: 2, enforceOrder: true)
    XCTAssertNotNil(operation.result, "An AsyncResultOperation should always have a result.")
    XCTAssertThrowsError(try operation.result.get(), "The operation result should contain an error.") { error in
      if let opError = error as? IntToStringAsyncResultOperation.Error {
        XCTAssertEqual(opError, .cancelled)
      } else {
        XCTFail("Wrong error type")
      }
    }
    XCTAssertTrue(operation.isCancelled)
  }

    func testSuccessfulInjectionTransformingOutput() {
      let operation1 = IntToStringAsyncResultOperation()
      let operation2 = StringToIntAsyncOperation()
      let operation3 = BlockOperation() // noise
      operation3.addDependency(operation2)
      operation1.input = 10

      let injection = BlockOperation { [unowned operation1, unowned operation2] in
        switch operation1.result {
        case .success(let value):
          operation2.input = value
        case .failure, .none:
          break
        }
      }

      injection.addDependency(operation1)
      operation2.addDependency(injection)

      let queue = OperationQueue()
      queue.addOperations([operation1, operation2, injection], waitUntilFinished: true)
      queue.addOperations([operation3], waitUntilFinished: false)
      XCTAssertNotNil(operation1.result)
      XCTAssertEqual(try? operation1.result?.get(), "10")
      XCTAssertEqual(operation2.output, 10)
    }

    func testFailingInjectionTransforminOutput() {
      let operation1 = IntToStringAsyncResultOperation()
      let operation2 = StringToIntAsyncOperation()
      let operation3 = BlockOperation() // noise
      operation3.addDependency(operation2)
      operation1.input = nil
      let injection = BlockOperation { [unowned operation1, unowned operation2] in
        switch operation1.result {
        case .success(let value):
          operation2.input = value
        case .failure, .none:
          break
        }
      }

      injection.addDependency(operation1)
      operation2.addDependency(injection)
      let queue = OperationQueue()
      queue.addOperations([operation1, operation2, injection], waitUntilFinished: true)
      XCTAssertNil(operation2.output)
    }
}

