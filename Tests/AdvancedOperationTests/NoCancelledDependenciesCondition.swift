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

final class NoCancelledDependenciesCondition: XCTestCase {
    
  func testIsMutuallyExclusive() {
    XCTAssertFalse(NoCancelledDependeciesCondition().isMutuallyExclusive)
  }

  func testTwoLevelCondition() {
    let queue = AdvancedOperationQueue()
    
    let operation1 = SleepyAsyncOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = XCTFailOperation()
    let operation4 = DelayOperation(interval: 1)

    operation1.addDependencies(dependencies: [operation2, operation3])
    operation1.addCondition(condition: NoCancelledDependeciesCondition())
    operation3.addDependency(operation4)
    operation3.addCondition(condition: NoCancelledDependeciesCondition()) // this operation will fail

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    XCTAssertTrue(operation4.isCancelled)
    XCTAssertTrue(operation3.failed)
    XCTAssertFalse(operation2.isCancelled)
    XCTAssertFalse(operation1.failed)
    XCTAssertFalse(operation1.isCancelled)

  }

//  func testStress() {
//    for i in 1...100 {
//      print(">>> \(i)")
//      testAllOperationCancelled()
//    }
//  }

  func testAllOperationCancelled() {
    do {
    let queue = AdvancedOperationQueue()

    let operation1 = SleepyAsyncOperation()
    operation1.name = "operation1"
    let operation2 = SleepyAsyncOperation()
    operation2.name = "operation2"
    let operation3 = XCTFailOperation()
    operation3.name = "operation3"
    let operation4 = DelayOperation(interval: 1)
    operation4.name = "operation4"

    operation1.addDependencies(dependencies: [operation2, operation3])
    //operation1.addCondition(condition: NoCancelledDependeciesCondition())
    operation3.addDependency(operation4)
    //operation3.addCondition(condition: NoCancelledDependeciesCondition()) // this operation will fail

    operation4.cancel()
    operation3.cancel() // it's pending and cancelled at the same time
    operation2.cancel()
    operation1.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    XCTAssertTrue(operation4.isCancelled)

    XCTAssertFalse(operation3.failed) // it's not failed because it's been cancelled before evaluating its conditions
    XCTAssertTrue(operation3.isCancelled)

    XCTAssertFalse(operation2.failed)
    XCTAssertTrue(operation2.isCancelled)

    XCTAssertFalse(operation1.failed) // it's not failed because it's been cancelled before evaluating its conditions
    XCTAssertTrue(operation1.isCancelled)
    }
  }

  func testWithNoFailedDependeciesCondition() {
    let queue = AdvancedOperationQueue()

    let operation1 = XCTFailOperation()
    let operation2 = SleepyAsyncOperation()
    let operation3 = XCTFailOperation()
    let operation4 = DelayOperation(interval: 1)

    operation1.addDependencies(dependencies: [operation2, operation3])
    operation1.addCondition(condition: NoCancelledDependeciesCondition())
    operation1.addCondition(condition: NoFailedDependenciesCondition())
    operation3.addDependency(operation4)
    operation3.addCondition(condition: NoCancelledDependeciesCondition())

    operation4.cancel()

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: true)
    XCTAssertTrue(operation4.isCancelled)
    XCTAssertFalse(operation4.failed)

    XCTAssertTrue(operation3.failed)

    XCTAssertFalse(operation2.isCancelled)
    XCTAssertFalse(operation2.failed)

    XCTAssertTrue(operation1.failed)
    XCTAssertFalse(operation1.isCancelled)
  }

}
