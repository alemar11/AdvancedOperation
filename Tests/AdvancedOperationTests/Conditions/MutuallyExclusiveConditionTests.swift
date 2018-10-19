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

  func testStress() {
    (1...5000).forEach { i in
      print(i)
      //testMutuallyExclusiveCondition()
      testMutuallyExclusiveConditionWithBlockOperations()
    }
  }

  // MARK: - Enqueue Mode

  func testMutuallyExclusiveCondition() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10

    //let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 0)
    let operation1 = AdvancedBlockOperation { complete in complete([]) }
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    operation1.addCondition(MutuallyExclusiveCondition(name: "SleepyAsyncOperation"))


    //let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    let operation2 = AdvancedBlockOperation { complete in complete([]) }
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    operation2.addCondition(MutuallyExclusiveCondition(name: "SleepyAsyncOperation"))

    operation1.name = "operation1"
    operation2.name = "operation2"

     operation1.useOSLog(TestsLog)
     operation2.useOSLog(TestsLog)

    queue.addOperations([operation1, operation2], waitUntilFinished: true)
    wait(for: [expectation1, expectation2], timeout: 10)
    //let remainingOperations = exclusivityManager.operations.count
    //XCTAssertEqual(remainingOperations, 0, "Expected 0 operations instead of \(remainingOperations).")
  }

  func testMutuallyExclusiveConditionWithtDifferentQueues() {
    let manager = ExclusivityManager()
    let queue1 = AdvancedOperationQueue(exclusivityManager: manager)
    queue1.maxConcurrentOperationCount = 10
    var text = ""

    let queue2 = AdvancedOperationQueue(exclusivityManager: manager)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { complete in
      text += "A"
      complete([])
    }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation2 = AdvancedBlockOperation { complete in
      text += "B"
      complete([])
    }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation3 = AdvancedBlockOperation { complete in
      text += "C"
      complete([])
    }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation4 = AdvancedBlockOperation { complete in
      text += "D"
      complete([])
    }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    queue1.addOperations([operation1, operation2], waitUntilFinished: true)
    queue2.addOperations([operation3, operation4], waitUntilFinished: true)

    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "ABCD")
  }

  func testMutuallyExclusiveConditionWithBlockOperations() {
    let lock = NSLock()
    let queue = AdvancedOperationQueue(exclusivityManager: ExclusivityManager())
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let operation1 = AdvancedBlockOperation { complete in
      lock.lock()
      text += "A "
      lock.unlock()
      complete([])
    }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)

    let operation2 = AdvancedBlockOperation { complete in
       lock.lock()
      text += "B "
       lock.unlock()
      complete([])
    }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)

    let operation3 = AdvancedBlockOperation { complete in
       lock.lock()
      text += "C."
      lock.unlock()
        complete([])
    }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation3, expectedValue: true)

    operation1.name = "op1"
    operation2.name = "op2"
    operation3.name = "op3"

    operation1.useOSLog(TestsLog)
    operation2.useOSLog(TestsLog)
    operation3.useOSLog(TestsLog)

    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)

    wait(for: [expectation1, expectation2, expectation3], timeout: 10, enforceOrder: false)
    XCTAssertEqual(text, "A B C.")

  }

  func testMultipleMutuallyExclusiveConditionsWithBlockOperations() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10
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

    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "test"))

    let operation4 = AdvancedBlockOperation { text += " 🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "test"))

    let operation5 = SleepyAsyncOperation(interval1: 2, interval2: 1, interval3: 2)
    operation5.completionBlock = {
      expectation5.fulfill()
    }
    operation5.addCondition(MutuallyExclusiveCondition(name: "test"))

    queue.addOperations([operation1, operation2, operation3, operation4, operation5], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }

  func testMultipleMutuallyExclusiveConditionsWithGroupOperations() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let delay = DelayOperation(interval: 2) // otherwise we actually don't know wich operation will start first

    let group1 = GroupOperation(operations: operation1, operation2, exclusivityManager: ExclusivityManager())
    group1.addDependency(delay)

    let operation3 = AdvancedBlockOperation { text += "C. " }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "test"))

    let operation4 = AdvancedBlockOperation { text += "🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation4.addCondition(MutuallyExclusiveCondition(name: "test"))

    queue.addOperations([delay, group1, operation3, operation4], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "C. 🎉A B ")
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

    let group = GroupOperation(operations: operation1, operation2, operation3, operation4, exclusivityManager: ExclusivityManager())
    group.addCompletionBlock { expectation5.fulfill() }
    group.start()
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "A B C. 🎉")
  }

  func testMultipleMutuallyExclusiveConditionsAndDependencies() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    var text1 = ""
    var text2 = ""

    let expectationDependency1 = expectation(description: "\(#function)\(#line)")
    let expectationDependency2 = expectation(description: "\(#function)\(#line)")

    let dependency1 = AdvancedBlockOperation { text1 += "1 " }
    dependency1.addCondition(MutuallyExclusiveCondition(name: "test"))
    dependency1.completionBlock = { expectationDependency1.fulfill() }

    let dependency2 = AdvancedBlockOperation { text1 += "2" }
    dependency2.addCondition(MutuallyExclusiveCondition(name: "test"))
    dependency2.completionBlock = { expectationDependency2.fulfill() }

    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text2 += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation1.addCondition(dependencyCondition1)

    let operation2 = AdvancedBlockOperation { text2 += "B" }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(dependencyCondition2)

    queue.addOperations([operation1, operation2], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
    XCTAssertEqual(text1, "1 2")
    XCTAssertEqual(text2, "A B")
  }

  func testExclusivityManager() {
    var text = ""
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: manager)
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

    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    XCTAssertEqual(manager.operations.keys.count, 0)
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)

    // this observer is added as the last one for the last operation
    let finalObserver = BlockObserver(didFinish: { (_, _) in
      sleep(2) // wait a bit longer...
      expectation4.fulfill()
    })
    operation3.addObserver(finalObserver)

    XCTAssertEqual(manager.operations.keys.count, 1)
    guard let key = manager.operations.keys.first else {
      return XCTAssertNotNil(manager.operations.keys.first)
    }
    XCTAssertEqual((manager.operations[key] ?? []).count, 3)

    queue.isSuspended = false
    waitForExpectations(timeout: 10)

    XCTAssertEqual(text, "A B C.")
    //TODO test in a different way
//    XCTAssertEqual(manager.operations.keys.count, 0)
//    XCTAssertEqual((manager.operations[key] ?? []).count, 0)
  }

  // MARK: - Cancel Mode

  func testMutuallyExclusiveConditionWithCancelMode() {
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
    queue.maxConcurrentOperationCount = 10

    let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 0)
    let condition = MutuallyExclusiveCondition(name: "SleepyAsyncOperation", mode: .cancel)
    XCTAssertEqual(condition.mutuallyExclusivityMode.description, "Enabled in cancel mode")

    operation1.addCondition(condition)

    let operation2 = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
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
    queue1.maxConcurrentOperationCount = 10
    var text = ""

    let queue2 = AdvancedOperationQueue(exclusivityManager: exclusivityManager)

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { complete in
      text += "A"
      sleep(1) // simulate a "time consuming" job
      complete([])
    }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation2 = AdvancedBlockOperation { complete in
      text += "B"
      complete([])
    }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))

    let operation3 = AdvancedBlockOperation { complete in
      text += "C"
      sleep(1)
      complete([])
    }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))

    let operation4 = AdvancedBlockOperation { complete in
      text += "D"
      complete([])
    }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))

    queue1.addOperations([operation1, operation2], waitUntilFinished: true)
    queue2.addOperations([operation3, operation4], waitUntilFinished: true)

    waitForExpectations(timeout: 10)
    XCTAssertEqual(text, "AC")
  }

  func testExclusivityManagerWithCancelMode() {
    var text = ""
    let exclusivityManager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusivityManager: exclusivityManager)
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

    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .cancel))
    operation3.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation", mode: .enqueue))

    XCTAssertEqual(exclusivityManager.operations.keys.count, 0)
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)

    // this observer is added as the last one for the last operation
    //    let finalObserver = BlockObserver(didFinish: { (_, _) in
    //      sleep(2) // wait a bit longer...
    //      expectation4.fulfill()
    //    })
    //operation3.addObserver(finalObserver)

    XCTAssertEqual(exclusivityManager.operations.keys.count, 1)
    guard let key = exclusivityManager.operations.keys.first else {
      return XCTAssertNotNil(exclusivityManager.operations.keys.first)
    }
    XCTAssertEqual((exclusivityManager.operations[key] ?? []).count, 2)

    queue.isSuspended = false
    waitForExpectations(timeout: 10)

    XCTAssertEqual(text, "A C.")
//    XCTAssertEqual(exclusivityManager.operations.keys.count, 0)
//    XCTAssertEqual((exclusivityManager.operations[key] ?? []).count, 0)
  }

  func testMultipleMutuallyExclusiveConditionsAndDependenciesWithCancelMode() {
    let queue = AdvancedOperationQueue(exclusivityManager: ExclusivityManager())
    var text1 = ""
    var text2 = ""

    let dependency1 = AdvancedBlockOperation { text1 += "1 " }
    dependency1.addCondition(MutuallyExclusiveCondition(name: "test", mode: .cancel))
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: dependency1, expectedValue: true)

    // dependency2 is going to be cancelled because it's added to the queue before dependency1 is completed (in this case is not yet started)
    let dependency2 = AdvancedBlockOperation { text1 += "2" }
    dependency2.addCondition(MutuallyExclusiveCondition(name: "test", mode: .cancel))
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: dependency2, expectedValue: true)

    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)

    let operation1 = AdvancedBlockOperation { text2 += "A " }
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    operation1.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation1.addCondition(dependencyCondition1)

    // operation2 is going to get cancelled because the dependency2 created as pre-condition is cancelled
    let operation2 = AdvancedBlockOperation { text2 += "B" }
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    operation2.addCondition(MutuallyExclusiveCondition(name: "AdvancedBlockOperation"))
    operation2.addCondition(dependencyCondition2)

    dependency1.name = "dep1"
    dependency2.name = "dep2"

    operation1.name = "op1"
    operation2.name = "op2"

//    operation1.useOSLog(TestsLog)
//    operation2.useOSLog(TestsLog)

    queue.addOperations([operation1, operation2], waitUntilFinished: false)
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 10)
    XCTAssertEqual(text1, "1 ")
    XCTAssertEqual(text2, "A ")

    XCTAssertTrue(dependency2.isCancelled)
    XCTAssertTrue(operation2.isCancelled)
  }

}

