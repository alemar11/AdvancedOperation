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
    let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    func evaluate(operation: AdvancedOperation) {
      XCTAssertEqual(operation.errors.count, 0)
      //TODO: this state could be a separate function
      XCTAssertFalse(operation.isReady)
      XCTAssertFalse(operation.isExecuting)
      XCTAssertFalse(operation.isCancelled)
      XCTAssertTrue(operation.isFinished)
    }
    
    #if os(Linux)
      waitForExpectations(timeout: 10) { (error) in
        XCTAssertNil(error)
        evaluate(operation: operation)
      }
    #else
      wait(for: [exp], timeout: 10)
      evaluate(operation: operation)
    #endif
    
  }
  
  #if !os(Linux)
  
  func testCancel() {
    let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    
    wait(for: [exp], timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertEqual(operation.errors.count, 0)
    //waitForExpectations(timeout: 10, handler: nil)
  }
  
  func testBailingOutEarly() {
    //let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = {
      //exp.fulfill()
    }
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.cancel()
    
    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    
    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    
    operation.waitUntilFinished()
    //wait(for: [exp], timeout: 10)
    //waitForExpectations(timeout: 10, handler: nil)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertEqual(operation.errors.count, 0)
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
    
    wait(for: [exp], timeout: 10)
    
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
    wait(for: [exp], timeout: 10)
    
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
    
    wait(for: [exp], timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertEqual(operation.errors.count, 1)
  }
  
  func testFinishWithErrors() {
    let operation = FailingOperation()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    
    wait(for: [expectation1], timeout: 5)
    XCTAssertEqual(operation.errors.count, 2)
  }
  
  #endif
  
}
