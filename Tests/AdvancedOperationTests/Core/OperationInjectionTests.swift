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

final class OperationInjectionTests: XCTestCase {
  override class func setUp() {
    #if swift(<5.1)
    AdvancedOperation.KVOCrashWorkaround.installFix()
    #endif
  }

  func testInputAndOutputValues() {
    let operation1 = IntToStringAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    operation1.input = 10
    operation1.start()
    wait(for: [expectation1], timeout: 3)
    XCTAssertEqual(operation1.output, "10")

    let operation2 = StringToIntAsyncOperation()
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    operation2.input = "10"
    operation2.start()
    wait(for: [expectation2], timeout: 3)
    XCTAssertEqual(operation2.output, 10)
  }

  func testSuccessfulInjectionBetweenOperations() {
    let queue = OperationQueue()
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    let injectionOperation = operation1.injectOutput(into: operation2)
    operation1.input = 10
    XCTAssertEqual(operation1.input, 10)
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)
    XCTAssertEqual(operation2.output, 10)
  }

  func testFailingInjectionBetweenOperations() {
    let queue = OperationQueue()
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    let injectionOperation = operation1.injectOutput(into: operation2)
    operation1.input = nil
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)
    XCTAssertNil(operation2.output)
  }

  func testFailingInjectionBetweenOperationsWhenTheOutputProducingOperationGetsCancelled() {
    let queue = OperationQueue()
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    let injectionOperation = operation1.injectOutput(into: operation2)
    operation1.input = 10
    operation1.cancel()
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)
    XCTAssertNil(operation2.output)
  }

  func testSuccessfulInjectionBetweenOperationsTransformingOutput() {
    // IntToStringOperation's output has its access synchronized with a lock to avoid data races while running macOS tests
    //
    // Data races are not detected if operations are added in this way:
    //
    //  queue.isSuspended = true
    //  queue.addOperation(operation1)
    //  queue.addOperation(operation2)
    //  queue.addOperation(injectionOperation)
    //  queue.isSuspended = false
    //  queue.waitUntilAllOperationsAreFinished()
    //
    // or in this way:
    //
    // let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    // let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    // queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: false)
    // wait(for: [expectation1], timeout: 4)
    //
    // instead of:
    //
    // queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)

    let queue = OperationQueue()
    let operation1 = IntToStringOperation()
    let operation2 = IntToStringOperation()
    let injectionOperation = operation1.injectOutput(into: operation2) { result -> Int? in
      if let result = result {
        return Int(result)
      } else {
        return nil
      }
    }
    operation1.input = 10
    XCTAssertEqual(operation1.input, 10)
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)

    XCTAssertEqual(operation1.output, "10")
    XCTAssertEqual(operation2.input, 10)
    XCTAssertEqual(operation2.output, "10")
  }

  func testSuccessfulInjectionBetweenAsyncOperationsTransformingOutput() {
    let queue = OperationQueue()
    let operation1 = IntToStringAsyncOperation()
    let operation2 = IntToStringAsyncOperation()
    let injectionOperation = operation1.injectOutput(into: operation2) { result -> Int? in
      if let result = result {
        return Int(result)
      } else {
        return nil
      }
    }
    operation1.input = 10
    XCTAssertEqual(operation1.input, 10)
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)

    XCTAssertEqual(operation1.output, "10")
    XCTAssertEqual(operation2.input, 10)
    XCTAssertEqual(operation2.output, "10")
  }

  func testFailingInjectionBetweenOperationsTransformingOutput() {
    let queue = OperationQueue()
    let operation1 = IntToStringOperation()
    let operation2 = IntToStringOperation()
    let injectionOperation = operation1.injectOutput(into: operation2) { _ -> Int? in return nil }
    operation1.input = 10
    XCTAssertEqual(operation1.input, 10)
    queue.addOperations([operation1, operation2, injectionOperation], waitUntilFinished: true)
    XCTAssertEqual(operation1.output, "10")
    XCTAssertNil(operation2.input)
    XCTAssertNil(operation2.output)
  }

  func testSuccessfulInjectionTransformingOutput() {
    let operation1 = IntToStringAsyncOperation()
    let operation2 = StringToIntAsyncOperation()
    let operation3 = BlockOperation() // noise
    operation3.addDependency(operation2)
    operation1.input = 10
    let injection = operation1.injectOutput(into: operation2) { $0 }
    let queue = OperationQueue()
    queue.addOperations([operation1, operation2, injection], waitUntilFinished: true)
    queue.addOperations([operation3], waitUntilFinished: false)
    XCTAssertEqual(operation1.output, "10")
    XCTAssertEqual(operation2.output, 10)
  }

  func testFailingInjectionTransforminOutput() {
    let operation1 = IntToStringAsyncOperation()
    let operation2 = IntToStringAsyncOperation()
    operation1.input = nil
    let injection = operation1.injectOutput(into: operation2) { _ in return nil }
    let queue = OperationQueue()
    queue.addOperations([operation1, operation2, injection], waitUntilFinished: true)
    XCTAssertNil(operation2.output)
  }

  func testInjectionTransformingOutputOfAnAlreadyCancelledOutputProducingOperation() {
    let operation1 = IntToStringAsyncOperation() // no input -> fails
    let operation2 = StringToIntAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    let injection = operation1.injectOutput(into: operation2) { $0 }
    let queue = OperationQueue()
    operation1.cancel()
    queue.addOperations([operation1, operation2, injection], waitUntilFinished: false)
    wait(for: [expectation1], timeout: 3)
  }
}
