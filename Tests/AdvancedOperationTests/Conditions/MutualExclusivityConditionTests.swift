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

class MutualExclusivityConditionTests: XCTestCase {
  
  func testEquality() {
    XCTAssertEqual(MutualExclusivityCondition(mode: .cancel(identifier: "id1")), MutualExclusivityCondition(mode: .cancel(identifier: "id1")))
    XCTAssertEqual(MutualExclusivityCondition(mode: .enqueue(identifier: "id1")), MutualExclusivityCondition(mode: .enqueue(identifier: "id1")))
    
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .cancel(identifier: "id1")), MutualExclusivityCondition(mode: .enqueue(identifier: "id1")))
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .enqueue(identifier: "id1")), MutualExclusivityCondition(mode: .cancel(identifier: "id1")))
    
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .cancel(identifier: "id1")), MutualExclusivityCondition(mode: .enqueue(identifier: "id2")))
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .enqueue(identifier: "id1")), MutualExclusivityCondition(mode: .cancel(identifier: "id2")))
    
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .cancel(identifier: "id1")), MutualExclusivityCondition(mode: .cancel(identifier: "id2")))
    XCTAssertNotEqual(MutualExclusivityCondition(mode: .enqueue(identifier: "id1")), MutualExclusivityCondition(mode: .enqueue(identifier: "id2")))
  }
  
  // MARK: - Enqueue Mode
  
  func testMutuallyExclusiveCondition() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    queue.qualityOfService = .userInitiated
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    operation1.completionBlock = {
      expectation1.fulfill()
    }
    
    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    operation1.addCondition(condition)
    
    
    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 1)
    operation2.completionBlock = {
      expectation2.fulfill()
    }
    operation2.addCondition(condition)
    
    queue.addOperations([operation2, operation1], waitUntilFinished: true)
    waitForExpectations(timeout: 0)
  }
  
  func testMutuallyExclusiveConditionWithBlockOperations() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    
    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    
    let operation1 = AdvancedBlockOperation { complete in
      text += "A "
      complete([])
    }
    operation1.addCondition(condition)
    operation1.completionBlock = {
      expectation1.fulfill()
    }
    
    let operation2 = AdvancedBlockOperation { complete in
      text += "B "
      complete([])
    }
    operation2.addCondition(condition)
    operation2.completionBlock = {
      expectation2.fulfill()
    }
    
    let operation3 = AdvancedBlockOperation {
      text += "C."
    }
    operation3.addCondition(condition)
    operation3.completionBlock = {
      expectation3.fulfill()
    }
    
    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
    /// An operation may start without waiting the completion block of the running one, so we cannot use `enforceOrder` to true.
    /// https://marcosantadev.com/4-ways-pass-data-operations-swift/
    wait(for: [expectation1, expectation2, expectation3], timeout: 10, enforceOrder: false)
    XCTAssertEqual(text, "A B C.")
  }
  
  func testMultipleMutuallyExclusiveConditionsWithBlockOperations() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""
    
    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition1)
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition1)
    
    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)
    
    let operation4 = AdvancedBlockOperation { text += " 🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition2)
    
    let operation5 = SleepyAsyncOperation(interval1: 2, interval2: 1, interval3: 2)
    operation5.completionBlock = {
      expectation5.fulfill()
    }
    operation5.addCondition(condition2)
    
    queue.addOperations([operation1, operation2, operation3, operation4, operation5], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }
  
  func testMultipleMutuallyExclusiveConditionsWithGroupOperations() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""
    
    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition1)
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition1)
    
    let group1 = GroupOperation(operations: operation1, operation2)
    group1.addCondition(condition1)
    
    let operation3 = AdvancedBlockOperation { text += "C. " }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)
    
    let operation4 = AdvancedBlockOperation { text += "🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition1)
    operation4.addCondition(condition2)
    
    queue.addOperations([group1, operation3, operation4], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }
  
  func testMultipleMutuallyExclusiveConditionsInsideGroupOperation() {
    var text = ""
    
    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let condition2 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition2"))
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition1)
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition1)
    
    let operation3 = AdvancedBlockOperation { text += "C. " }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition1)
    operation3.addCondition(condition2)
    
    let operation4 = AdvancedBlockOperation { text += "🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition1)
    operation4.addCondition(condition2)
    
    let group = GroupOperation(operations: operation1, operation2, operation3, operation4)
    group.addCompletionBlock { expectation5.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }
  
  func testExclusivityManager() {
    var text = ""
    let condition1 = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let queue = AdvancedOperationQueue()
    queue.isSuspended = true
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    
    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    
    operation1.addCondition(condition1)
    operation2.addCondition(condition1)
    operation3.addCondition(condition1)
    
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 0)
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    
    // this observer is added as the last one for the last operation
    let finalObserver = BlockObserver(didFinish: { (_, _) in
      sleep(2) // wait a bit longer...
      expectation4.fulfill()
    })
    operation3.addObserver(finalObserver)
    
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 1)
    guard let key = queue.exclusivityManager.operations.keys.first else {
      return XCTAssertNotNil(queue.exclusivityManager.operations.keys.first)
    }
    XCTAssertEqual((queue.exclusivityManager.operations[key] ?? []).count, 3)
    
    queue.isSuspended = false
    waitForExpectations(timeout: 10)
    
    XCTAssertEqual(text, "A B C.")
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 1)
    XCTAssertEqual((queue.exclusivityManager.operations[key] ?? []).count, 0)
  }
  
  // MARK: - Cancel Mode
  func testStress() {
    (1...10).forEach { (index) in
      print("------------------------\(index)")
      testMutuallyExclusiveConditionWithCancelMode()
    }
  }
  
  func testMutuallyExclusiveConditionWithCancelMode() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 0)
    operation1.completionBlock = {
      expectation1.fulfill()
    }

    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let conditionCancel = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))
    
    operation1.addCondition(conditionCancel)

    let operation2 = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
    operation2.completionBlock = {
      print("1")
      expectation2.fulfill()
    }
    operation2.addCondition(condition)

    // operation1 will be cancelled only if operation2 is still running.
    queue.addOperations([operation2, operation1], waitUntilFinished: true)
    print("2")
    waitForExpectations(timeout: 1)

    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isFinished)

    XCTAssertTrue(operation1.isCancelled)
    XCTAssertFalse(operation2.isCancelled)

    print(operation1.isFinished)
    print(operation2.isFinished)
  }
  
  func testExclusivityManagerWithCancelMode() {
    var text = ""
    let queue = AdvancedOperationQueue()
    
    let condition = MutualExclusivityCondition(mode: .enqueue(identifier: "condition1"))
    let conditionCancel = MutualExclusivityCondition(mode: .cancel(identifier: "condition1"))
    
    queue.isSuspended = true
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    //let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    
    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    
    operation1.addCondition(condition)
    operation2.addCondition(conditionCancel)
    operation3.addCondition(condition)
    
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 0)
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    
    // this observer is added as the last one for the last operation
    //    let finalObserver = BlockObserver(didFinish: { (_, _) in
    //      sleep(2) // wait a bit longer...
    //      expectation4.fulfill()
    //    })
    //operation3.addObserver(finalObserver)
    
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 1)
    guard let key = queue.exclusivityManager.operations.keys.first else {
      return XCTAssertNotNil(queue.exclusivityManager.operations.keys.first)
    }
    XCTAssertEqual((queue.exclusivityManager.operations[key] ?? []).count, 2)
    
    queue.isSuspended = false
    waitForExpectations(timeout: 10)
    
    XCTAssertEqual(text, "A C.")
    XCTAssertEqual(queue.exclusivityManager.operations.keys.count, 1)
    XCTAssertEqual((queue.exclusivityManager.operations[key] ?? []).count, 0)
  }
  
}
