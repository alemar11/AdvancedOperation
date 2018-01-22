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

#if os(Linux)

import XCTest
@testable import AdvancedOperation

extension LinuxBehaviorsTests {

  static var allTests = [
    ("testReadinessWithoutOperationQueue", testReadinessWithoutOperationQueue),
    ("testReadinessWithOperationQueue", testReadinessWithOperationQueue),
    ("testReadinessWithDependenciesInOperationQueue", testReadinessWithDependenciesInOperationQueue),
    //("testAddOperationsInAdvancedOperationQueue", testAddOperationsInAdvancedOperationQueue)
  ]

}

class LinuxBehaviorsTests: XCTestCase {
    
  // It appears that on Linux, the operation readiness is ALWAYS set to 'false' by default.
  // It changes to 'true' ONLY if an operation is added to an OperationQueue regardless of its associated dependencies.

  func testReadinessWithoutOperationQueue() {
    let operation1 = BlockOperation(block: {})
    let operation2 = BlockOperation(block: {})
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)
    print(operation1.isReady)
    print(operation2.isReady)

    operation1.addDependency(operation2)
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)
    print(operation1.isReady)
    print(operation2.isReady)

    operation2.start()
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)
    print(operation1.isReady)
    print(operation2.isReady)

    operation1.start()
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)
    print(operation1.isReady)
    print(operation2.isReady)
  }

  func testReadinessWithOperationQueue() {
    let operation1 = BlockOperation(block: {})
    let operation2 = BlockOperation(block: {})
    let queue = OperationQueue()
    print(operation1.isReady)
    print(operation2.isReady)
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)

    queue.addOperations([operation1, operation2], waitUntilFinished: true)
    print(operation1.isReady)
    print(operation2.isReady)
    XCTAssertTrue(operation1.isReady)
    XCTAssertTrue(operation2.isReady)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
  }

  func testReadinessWithDependenciesInOperationQueue() {
    let operation1 = BlockOperation(block: {})
    let operation2 = BlockOperation(block: {})
    let operation3 = SleepyOperation()
    let queue = OperationQueue()

    print(operation1.isReady)
    print(operation2.isReady)

    operation1.addDependency(operation2)
    print(operation1.isReady)
    print(operation2.isReady)
    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)
    XCTAssertFalse(operation3.isReady)

    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: true)
    print(operation1.isReady)
    print(operation2.isReady)
    XCTAssertTrue(operation1.isReady)
    XCTAssertTrue(operation2.isReady)
    XCTAssertTrue(operation3.isReady)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation3.isFinished)
  }

  func testAddOperationsInAdvancedOperationQueue() {
    let operation1 = BlockOperation(block: {})
    let operation2 = BlockOperation(block: {})
    let queue = AdvancedOperationQueue()

    XCTAssertFalse(operation1.isReady)
    XCTAssertFalse(operation2.isReady)

    queue.addOperations([operation1, operation2], waitUntilFinished: true) // FIXME: This causes an infinite loop on Linux
    XCTAssertTrue(operation1.isReady)
    XCTAssertTrue(operation2.isReady)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)
  }
    
}

#endif
