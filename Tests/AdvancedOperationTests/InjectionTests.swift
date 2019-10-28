//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
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

final class InjectionTests: XCTestCase {
//  func testInputAndOutput() {
//    let operation1 = IntToStringOperation()
//    operation1.input = 10
//    operation1.start()
//    XCTAssertEqual(operation1.output, "10")
//
//    let operation2 = StringToIntOperation()
//    operation2.input = "10"
//    operation2.start()
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testInjectionMixedWithOtherOperation() {
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//    let operation3 = BlockOperation()
//    operation3.addDependency(operation2)
//    operation1.input = 10
//    operation1.injectOutput(into: operation2)
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//    queue.addOperations([operation3], waitUntilFinished: false)
//
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testInjectionUsingInstanceMethodAndWaitUntilFinished() {
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//    operation1.input = 10
//    operation1.injectOutput(into: operation2)
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testTransformableInjectionInstanceMethodAndWaitUntilFinishedUsing() {
//    let operation1 = IntToStringOperation()
//    let operation2 = IntToStringOperation()
//    operation1.input = 10
//    operation1.injectOutput(into: operation2) { value -> Int? in
//      if let value = value {
//        return Int(value)
//      } else {
//        return nil
//      }
//    }
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//
//    XCTAssertEqual(operation2.output, "10")
//  }
//
//  func testTransformableInjectionWithNilResultUsingInstanceMethodAndWaitUntilFinished() {
//    let operation1 = IntToStringOperation()
//    let operation2 = IntToStringOperation()
//    operation1.input = 404
//    operation1.injectOutput(into: operation2) { value -> Int? in
//      if let value = value {
//        return Int(value)
//      } else {
//        return nil
//      }
//    }
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//
//    XCTAssertNil(operation2.output)
//  }
//
//  func testInjectionWithoutWaitingUntilFinished() {
//    let expectation = self.expectation(description: "\(#function)\(#line)")
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//    let operation3 = AdvancedBlockOperation {
//      expectation.fulfill()
//    }
//    operation3.addDependency(operation2)
//
//    operation1.input = 10
//    operation1.injectOutput(into: operation2)
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
//
//    waitForExpectations(timeout: 3)
//    XCTAssertEqual(operation2.input, "10")
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testInjectionInputNotOptionalRequirement() {
//    let expectation1 = self.expectation(description: "\(#function)\(#line)")
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//    operation2.completionBlock = {
//      expectation1.fulfill()
//    }
//    operation1.input = 2000 // values greater than 1000 will produce a nil output when executing 😎
//    operation1.injectOutput(into: operation2)
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: false)
//
//    waitForExpectations(timeout: 3)
//    XCTAssertNil(operation2.input)
//    XCTAssertNil(operation2.output)
//  }
//
//  func testInputInjectionWithAnAlreadyCancelledOutputProducingOperation() {
//    let operation1 = IntToStringOperation() // no input -> fails
//    let operation2 = StringToIntOperation()
//    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
//    operation1.injectOutput(into: operation2)
//    let queue = OperationQueue()
//
//    operation1.cancel()
//    queue.addOperations([operation1, operation2], waitUntilFinished: false)
//
//    wait(for: [expectation1], timeout: 10)
//  }
//
//  func testMemoryLeaks() {
//    let queue = OperationQueue()
//    var operation1: IntToStringOperation? = IntToStringOperation()
//    var operation2: StringToIntOperation? = StringToIntOperation()
//
//    weak var weakOperation1 = operation1
//    weak var weakOperation2 = operation2
//
//    autoreleasepool {
//      operation1!.input = 10
//      operation1!.injectOutput(into: operation2!)
//
//      queue.addOperations([operation1!, operation2!], waitUntilFinished: true)
//
//      XCTAssertEqual(operation2!.output, 10)
//
//      // replacing operations with new ones to force deinit on the previous ones.
//      operation1 = IntToStringOperation()
//      operation2 = StringToIntOperation()
//    }
//
//    // sometimes the OperationQueue needs more time to remove the operations
//    usleep(5000) // //will sleep for .005 seconds
//    // while weakOperation1 != nil || weakOperation2 != nil { }
//
//    XCTAssertNil(weakOperation1)
//    XCTAssertNil(weakOperation2)
//  }
//
//  func testInjectionWithMutuallyExclusiveConditionInEnqueueMode() {
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//
//    operation1.exclusivityManager = .shared
//    operation1.addCondition(MutualExclusivityCondition(mode: .enqueue(identifier: "condition1")))
//    operation2.exclusivityManager = .shared
//    operation2.addCondition(MutualExclusivityCondition(mode: .enqueue(identifier: "condition1")))
//
//    operation1.input = 10
//    operation1.injectOutput(into: operation2) // After an injection, operation2 will be dependant from operation1
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testInjectionWithMutuallyExclusiveConditionInCancelMode() {
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//
//    operation1.exclusivityManager = .shared
//    operation1.addCondition(MutualExclusivityCondition(mode: .cancel(identifier: "condition1")))
//    operation2.exclusivityManager = .shared
//    operation2.addCondition(MutualExclusivityCondition(mode: .cancel(identifier: "condition1")))
//
//    operation1.input = 10
//    operation1.injectOutput(into: operation2) // After an injection, operation2 will be dependant from operation1
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//    XCTAssertEqual(operation2.output, 10)
//  }
//
//  func testInjectionWithNoFailedDependenciesConditions() {
//    let operation1 = IntToStringOperation()
//    let operation2 = StringToIntOperation()
//
//    operation2.addCondition(NoFailedDependenciesCondition(ignoreCancellations: false))
//
//    operation1.input = 10
//    operation1.injectOutput(into: operation2) // After an injection, operation2 will be dependant from operation1
//    operation1.cancel()
//    let queue = OperationQueue()
//    queue.addOperations([operation1, operation2], waitUntilFinished: true)
//    XCTAssertNil(operation2.output)
//    XCTAssertNil(operation2.input)
//    XCTAssertTrue(operation2.isCancelled)
//  }

  //  func testInvestigationWithStandardDependency() {
  //    let operation1 = BlockOperation {}
  //    let operation3 = BlockOperation {}
  //    let operation2 = BlockOperation { [unowned operation1, unowned operation3] in }
  //    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
  //
  //    operation3.addDependency(operation2)
  //    operation2.addDependency(operation1)
  //    operation1.cancel()
  //
  //    let queue = OperationQueue()
  //
  //    /// ✅works
  //    queue.addOperations([operation1, operation3, operation2], waitUntilFinished: false)
  //
  //    // ⚠️ sporadic failures (i.e. 5 failures on 10_000 executions.)
  //    // when referencing operation1 and operation3 inside operation2 (with weak or unowned)
  //
  //    // queue.addOperation(operation1)
  //    // queue.addOperation(operation3)
  //    // queue.addOperation(operation2)
  //
  //    wait(for: [expectation1], timeout: 20)
  //  }
}
