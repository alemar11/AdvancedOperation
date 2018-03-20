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

class MutuallyExclusiveConditionTests: XCTestCase {

  func testIsMutuallyExclusive() {
    XCTAssertTrue(MutuallyExclusiveCondition<XCTestCase>().isMutuallyExclusive)
  }

  func testEvaluate() {
    let operation = AdvancedBlockOperation(block: {})
    let condition = MutuallyExclusiveCondition<XCTestCase>()
    let expectation1 = expectation(description: "\(#function)\(#line)")
    condition.evaluate(for: operation) { (result) in
      switch result {
      case .satisfied:
        break
      default:
        XCTFail("Unexpected result: \(result)")
      }
      expectation1.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testMutuallyExclusiveCondition() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")

    let operation1 = SleepyAsyncOperation(interval1: 0, interval2: 0, interval3: 0)
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition: MutuallyExclusiveCondition<SleepyAsyncOperation>())

    let operation2 = SleepyAsyncOperation(interval1: 5, interval2: 5, interval3: 5)
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition: MutuallyExclusiveCondition<SleepyAsyncOperation>())

    queue.addOperations([operation2, operation1], waitUntilFinished: true)
    wait(for: [expectation2, expectation1], timeout: 0, enforceOrder: true)
  }

  func testMutuallyExclusiveConditionWithBlockOperations() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
    wait(for: [expectation1, expectation2, expectation3], timeout: 3, enforceOrder: true)
    XCTAssertEqual(text, "A B C.")
  }

  func testMultipleMutuallyExclusiveConditionsWithBlockOperations() {
    let queue = AdvancedOperationQueue()
    queue.maxConcurrentOperationCount = 10
    var text = ""

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())
    operation3.addCondition(condition: MutuallyExclusiveCondition<XCTest>())

    let operation4 = AdvancedBlockOperation { text += " 🎉" }
    operation4.completionBlock = { expectation4.fulfill() }
    operation4.addCondition(condition: MutuallyExclusiveCondition<XCTest>())

    queue.addOperations([operation1, operation2, operation3, operation4], waitUntilFinished: false)
    wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 3, enforceOrder: true)
    XCTAssertEqual(text, "A B C. 🎉")
  }

  func testExclusivityManager() {
    var text = ""
    let manager = ExclusivityManager()
    let queue = AdvancedOperationQueue(exclusibityManager: manager)
    queue.isSuspended = true

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")

    let operation1 = AdvancedBlockOperation { text += "A " }
    operation1.completionBlock = { expectation1.fulfill() }
    operation1.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation2 = AdvancedBlockOperation { text += "B " }
    operation2.completionBlock = { expectation2.fulfill() }
    operation2.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    let operation3 = AdvancedBlockOperation { text += "C." }
    operation3.completionBlock = { expectation3.fulfill() }
    operation3.addCondition(condition: MutuallyExclusiveCondition<AdvancedBlockOperation>())

    XCTAssertEqual(manager.operations.keys.count, 0)
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)

    XCTAssertEqual(manager.operations.keys.count, 1)
    guard let key = manager.operations.keys.first else {
      return XCTAssertNotNil(manager.operations.keys.first)
    }
    XCTAssertEqual((manager.operations[key] ?? []).count, 3)

    queue.isSuspended = false
    wait(for: [expectation1, expectation2, expectation3], timeout: 10, enforceOrder: true)
    XCTAssertEqual(text, "A B C.")
    XCTAssertEqual(manager.operations.keys.count, 1)
    XCTAssertEqual((manager.operations[key] ?? []).count, 0)
  }

}
