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

extension AdvancedBlockOperationTests {
  
  static var allTests = [
    ("testCancel", testCancel),
    ("testEarlyBailOut", testEarlyBailOut),
    ("testBlockOperationWithAsyncQueue", testBlockOperationWithAsyncQueue),
    ("testBlockOperationWithAsyncQueueFinishedWithErrors", testBlockOperationWithAsyncQueueFinishedWithErrors),
    ("testBlockOperationWithDispatchQueue", testBlockOperationWithDispatchQueue),
    ("testMemoryLeak", testMemoryLeak)
  ]
  
}

class AdvancedBlockOperationTests: XCTestCase {
  
  func testCancel() {
    let operation = AdvancedBlockOperation { complete in
      DispatchQueue(label: "org.tinrobots.AdvancedOperation.\(#function)", attributes: .concurrent).async {
        sleep(1)
        sleep(2)
        complete([])
      }
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    operation.cancel()
    
    waitForExpectations(timeout: 4)
    print(operation)
    XCTAssertOperationCancelled(operation: operation)
  }
  
  func testEarlyBailOut() {
    let operation = AdvancedBlockOperation { complete in
      complete([])
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.cancel()
    operation.start()
    
    waitForExpectations(timeout: 4)
    XCTAssertOperationCancelled(operation: operation)
  }
  
  func testBlockOperationWithAsyncQueue() {
    let operation = AdvancedBlockOperation { complete in
      XCTAssertTrue(Thread.isMainThread)
      DispatchQueue(label: "org.tinrobots.AdvancedOperation.\(#function)", attributes: .concurrent).async {
        sleep(1)
        sleep(2)
        complete([])
      }
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    
    waitForExpectations(timeout: 4)
    XCTAssertOperationFinished(operation: operation)
  }
  
  func testBlockOperationWithAsyncQueueFinishedWithErrors () {
    let errors = [MockError.generic(date: Date()), MockError.failed]
    
    var object = NSObject()
    weak var weakObject = object
    
    var operation = AdvancedBlockOperation { [object] complete in
      DispatchQueue(label: "org.tinrobots.AdvancedOperation.\(#function)", attributes: .concurrent).async {
        sleep(1)
        sleep(1)
        _ = object
        complete(errors)
      }
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    
    waitForExpectations(timeout: 3)
    XCTAssertOperationFinished(operation: operation, errors: errors)
    
    // Memory leaks test: once release the operation, the captured object (by reference) should be nil (weakObject)
    operation = AdvancedBlockOperation(block: {})
    object = NSObject()
    XCTAssertNil(weakObject)
  }
  
  func testBlockOperationWithDispatchQueue() {
    let queue = DispatchQueue(label: "org.tinrobots.AdvancedOperation.\(#function)")
    let operation = AdvancedBlockOperation(queue: queue) {
      XCTAssertTrue(!Thread.isMainThread)
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    waitForExpectations(timeout: 3)
  }
  
  func testMemoryLeak() {
    var object = NSObject()
    weak var weakObject = object
    
    var operation = AdvancedBlockOperation { [object] complete in
      DispatchQueue(label: "org.tinrobots.AdvancedOperation.\(#function)", attributes: .concurrent).async {
        _ = object
        complete([])
      }
    }
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock { expectation1.fulfill() }
    operation.start()
    
    waitForExpectations(timeout: 3)
    
    // Memory leaks test: once release the operation, the captured object (by reference) should be nil (weakObject)
    operation = AdvancedBlockOperation(block: {})
    object = NSObject()
    XCTAssertNil(weakObject)
  }
  
}
