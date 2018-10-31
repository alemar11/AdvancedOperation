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

final class MutuallyExclusiveConditionTests: XCTestCase {
  
  func testIsMutuallyExclusive() {
    XCTAssertTrue(MutuallyExclusiveCondition(name: "test").mutuallyExclusivityMode == .enqueue)
    XCTAssertEqual(MutuallyExclusiveCondition(name: "test").mutuallyExclusivityMode.description, "Enabled in enqueue mode")
  }
  
  // MARK: - Enqueue Mode
  
  func testDependencyCycle() {
    let queue = AdvancedOperationQueue(exclusivityManager: ExclusivityManager())
    
    let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 1)
    operation1.addCondition(MutuallyExclusiveCondition(name: "A"))
    operation1.name = "operation1"
    
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    operation2.addCondition(MutuallyExclusiveCondition(name: "A"))
    operation2.name = "operation2"
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    
    operation2.addDependency(operation1)
    
    // if operation2 is added before operation1 but operation2 depends on operation1, then the exclusivity category is "skipped"
    // to avoid a dependecy cycle between the two operations.
    queue.addOperation(operation2)
    queue.addOperation(operation1)
    
    wait(for: [expectation1, expectation2], timeout: 15)
  }
  
  func testMutuallyExclusiveConditionWithtDifferentQueues() {
    let manager = ExclusivityManager()
    let queue1 = AdvancedOperationQueue(exclusivityManager: manager)
    queue1.maxConcurrentOperationCount = 10
    var text = ""
    let lock = NSLock()
    
    let queue2 = AdvancedOperationQueue(exclusivityManager: manager)
    
    let operation1 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "A"
      lock.unlock()
      complete([])
    }
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation2 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "B"
      lock.unlock()
      complete([])
    }
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation3 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "C"
      lock.unlock()
      complete([])
    }
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation4 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "D"
      lock.unlock()
      complete([])
    }
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"
    
    operation1.useOSLog(TestsLog)
    operation2.useOSLog(TestsLog)
    operation3.useOSLog(TestsLog)
    operation4.useOSLog(TestsLog)
    
    queue1.addOperations([operation1, operation2], waitUntilFinished: false)
    queue2.addOperations([operation3, operation4], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    XCTAssertEqual(text, "ABCD")
  }
  
  func testMutuallyExclusiveConditionWithBlockOperations() {
    let queue = AdvancedOperationQueue(exclusivityManager: ExclusivityManager())
    queue.maxConcurrentOperationCount = 10
    var text = ""
    
    let operation1 = AdvancedBlockOperation { complete in
      text += "A "
      complete([])
    }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    
    let operation2 = AdvancedBlockOperation { complete in
      text += "B "
      complete([])
    }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    
    let operation3 = AdvancedBlockOperation { complete in
      text += "C."
      complete([])
    }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    
    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    
    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
    
    wait(for: [expectation1, expectation2, expectation3], timeout: 10)
    XCTAssertEqual(text, "A B C.")
  }
  
  func testMultipleMutuallyExclusiveConditionsWithBlockOperations() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10
    var text = ""
    
    let operation1 = SleepyBlockOperation(interval: 3) { text += "A " }
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation3 = SleepyBlockOperation(interval: 1)  { text += "C." }
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "test"))
    
    let operation4 = SleepyBlockOperation(interval: 0)  { text += " 🎉" }
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation4, expectedValue: true)
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "test"))
    
    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"
    
    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }
  
  func testMultipleMutuallyExclusiveConditionsInsideAGroupOperation() {
    var text = ""
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation3 = AdvancedBlockOperation { text += "C. " }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "test"))
    
    let operation4 = AdvancedBlockOperation { text += "🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation4.addCondition(MutuallyExclusiveCondition(name: "test"))
    
    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    operation4.name = "operation4"
    
    let group = GroupOperation(operations: operation1, operation2, operation3, operation4, exclusivityManager: ExclusivityManager())
    group.addCompletionBlock { expectation5.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }
  
  func testExclusivityManager() { // TODO: test crashed
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    var text = ""
    let queue = AdvancedOperationQueue(exclusivityManager: ExclusivityManager())
    queue.isSuspended = true
    
    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    
    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    operation1.name = "operation1"
    operation2.name = "operation2"
    operation3.name = "operation3"
    
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    
    // this observer is added as the last one for the last operation
    let finalObserver = BlockObserver(didFinish: { (_, _) in
      sleep(2) // wait a bit longer...
      expectation4.fulfill()
    })
    operation3.addObserver(finalObserver)
    
    queue.isSuspended = false
    waitForExpectations(timeout: 10)
    
    XCTAssertEqual(text, "A B C.")
  }
  
  // MARK: - Cancel Mode
  
  func testStress() {
    (1...500).forEach { i in
      print(i)
      testMutuallyExclusiveConditionWithCancelMode()
    }
  }
  
  func testMutuallyExclusiveConditionWithCancelMode() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10
    
    let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    let condition = MutuallyExclusiveCondition(name: "SleepyAsyncOperation", mode: .cancel)
    XCTAssertEqual(condition.mutuallyExclusivityMode.description, "Enabled in cancel mode")
    
    operation1.addCondition(condition)
    
    let operation2 = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    operation2.addCondition(MutuallyExclusiveCondition(name: "SleepyAsyncOperation"))
    
    queue.addOperations([operation2, operation1], waitUntilFinished: true)
    
    XCTAssertTrue(operation1.isCancelled)
    XCTAssertNotNil(operation1.errors)
    XCTAssertTrue(operation2.isFinished)
    XCTAssertTrue(operation2.errors.isEmpty)
  }
  
  func testMutuallyExclusiveConditionWithtDifferentQueuesWithCancelMode() {
    let exclusivityManager = ExclusivityManager()
    let queue1 = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    let lock = NSLock()
    queue1.maxConcurrentOperationCount = 10
    var text = ""
    
    let queue2 = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "A"
      lock.unlock()
      sleep(1) // simulate a "time consuming" job
      complete([])
    }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation2 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "B"
      lock.unlock()
      complete([])
    }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))
    
    let operation3 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "C"
      lock.unlock()
      sleep(1)
      complete([])
    }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    
    let operation4 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "D"
      lock.unlock()
      complete([])
    }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))
    
    queue1.addOperations([operation1, operation2], waitUntilFinished: true)
    queue2.addOperations([operation3, operation4], waitUntilFinished: true)
    
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "AC")
    
    XCTAssertTrue(operation4.isCancelled)
  }
  
  func testExclusivityManagerWithCancelMode() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let lock = NSLock()
    var text = ""
    let exclusivityManager = ExclusivityManager()
    
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.isSuspended = true
    
    let operation1 = AdvancedBlockOperation {
      lock.lock()
      text += "A "
      lock.unlock()
    }
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation {
      lock.lock()
      text += "B "
      lock.unlock()
    }
    operation2.completionBlock = { expectation2.fulfill() }
    
    let operation3 = AdvancedBlockOperation {
      lock.unlock()
      text += "C."
      lock.unlock()
    }
    operation3.completionBlock = { expectation3.fulfill() }
    
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .enqueue))
    
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    
    queue.isSuspended = false
    
    waitForExpectations(timeout: 10)
    
    XCTAssertEqual(text, "A C.")
  }
  
}

