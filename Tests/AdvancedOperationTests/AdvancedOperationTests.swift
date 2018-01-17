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

extension AdvancedOperationTests {
  //TODO: complete this list
  static var allTests = [
    ("testStart", testStart),
    //("testCancel", testCancel),
    //("testBailingOutEarly", testBailingOutEarly),
    //("testObservers", testObservers)
  ]
}

class AdvancedOperationTests: XCTestCase {
  
  func testStart() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }
    
    OperationState.ready.evaluate(operation: operation)
    
    operation.start()
    OperationState.started.evaluate(operation: operation)
    
    waitForExpectations(timeout: 10)
    OperationState.finished(errors: []).evaluate(operation: operation)
  }
  
  #if !os(Linux)
  
  func testCancel() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { expectation1.fulfill() }
    
    OperationState.ready.evaluate(operation: operation)
    
    operation.start()
    OperationState.started.evaluate(operation: operation)
    
    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)

    waitForExpectations(timeout: 10)
    OperationState.cancelled(error: nil).evaluate(operation: operation)
  }
  
  func testBailingOutEarly() {
    let operation = SleepyAsyncOperation()

    OperationState.ready.evaluate(operation: operation)
    
    operation.cancel()
    
    operation.start()
    OperationState.cancelled(error: nil).evaluate(operation: operation)
    
    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    
    operation.waitUntilFinished()
    OperationState.cancelled(error: nil).evaluate(operation: operation)
  }
  
  fileprivate class Observer: OperationObserving {
    
    var didStartCount = 0
    var didFinishCount = 0
    var didCancelCount = 0
    
    func operationWillPerform(operation: AdvancedOperation) {
      didStartCount += 1
    }
    
    func operationDidPerform(operation: AdvancedOperation, withErrors errors: [Error]) {
      didFinishCount += 1
    }
    
    func operationWillCancel(operation: AdvancedOperation, withErrors errors: [Error]) {
      //
    }
    
    func operationDidCancel(operation: AdvancedOperation, withErrors errors: [Error]) {
      didCancelCount += 1
    }
    
  }
  
  func testObservers() {
    
    let exp = expectation(description: "\(#function)\(#line)")
    let observer = Observer()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer: observer)
    
    operation.completionBlock = { exp.fulfill() }
    
    operation.start()
    
    waitForExpectations(timeout: 10)
    
    sleep(5) // make sure there are no other effects
    
    XCTAssertEqual(observer.didStartCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
    
  }
  
  
  func testObserversWithACancelCommand() {
    
    let exp = expectation(description: "\(#function)\(#line)")
    let observer = Observer()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer: observer)
    
    operation.completionBlock = { exp.fulfill() }
    
    operation.start()
    operation.cancel()
    waitForExpectations(timeout: 10)
    
    sleep(5) // make sure there are no other effects
    
    XCTAssertEqual(observer.didStartCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.didCancelCount, 1)
    XCTAssertEqual(operation.errors.count, 0)
  }
  
  
  func testCancelWithErrors() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }
    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.cancel(error: MockError.test)
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertEqual(operation.errors.count, 1)
  }
  
  func testFinishWithErrors() {
    let operation = FailingOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    
    waitForExpectations(timeout: 10)
    XCTAssertEqual(operation.errors.count, 2)
  }
  
  #endif
  
}
