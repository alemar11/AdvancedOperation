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

class OperationConditionTests: XCTestCase {
  
  func testDependency() {
    let queue = AdvancedOperationQueue()
    
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = SleepyOperation()
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = SleepyOperation()
    operation2.completionBlock = { expectation2.fulfill() }
    
    let dependency1 = AdvancedBlockOperation { }
    dependency1.completionBlock = { expectation3.fulfill() }
    
    let dependency2 = AdvancedBlockOperation { }
    dependency2.completionBlock = { expectation4.fulfill() }
    
    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)
    
    operation1.addCondition(dependencyCondition1)
    operation2.addCondition(dependencyCondition2)
    
    queue.addOperations([operation1, operation2], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
  }
  
  func testGroupOperationWithDependencies() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = AdvancedBlockOperation { }
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation { }
    operation2.completionBlock = { expectation2.fulfill() }
    
    let group = GroupOperation()
    group.completionBlock = {
      expectation5.fulfill()
    }
    
    let dependency1 = AdvancedBlockOperation { sleep(2) }
    dependency1.completionBlock = {
      XCTAssertFalse(group.isFinished)
      expectation3.fulfill()
    }
    
    let dependency2 = AdvancedBlockOperation { sleep(4) }
    dependency2.completionBlock = {
      XCTAssertFalse(group.isFinished)
      expectation4.fulfill()
    }
    
    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)
    
    operation1.addCondition(dependencyCondition1)
    operation2.addCondition(dependencyCondition2)
    
    group.addOperation(operation: operation1)
    group.addOperation(operation: operation2)
    
    group.start()
    
    waitForExpectations(timeout: 10)
  }
  
  //  func testStress() {
  //    for i in 1...100 {
  //      print("\(i)")
  //      testGroupOperationWithDependencies()
  //      testCancelledGroupOperationWithDependencies()
  //    }
  //  }
  
  func testCancelledGroupOperationWithDependencies() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    
    //    let observer = BlockObserver(willExecute: { (operation) in
    //      print("\(operation.name!) willExecute")
    //    }, didProduce: { (from, to) in
    //
    //    }, willCancel: { (operation, errors) in
    //      print("\(operation.name!) willCancel")
    //    }, didCancel: { (operation, errors) in
    //      print("\(operation.name!) didCancel")
    //    }, willFinish: { (operation, errors) in
    //      print("\(operation.name!) willFinish")
    //    }) { (operation, errors) in
    //      print("\(operation.name!) didFinish")
    //    }
    
    let operation1 = AdvancedBlockOperation { }
    operation1.name = "operation1"
    operation1.completionBlock = { expectation1.fulfill() }
    
    let operation2 = AdvancedBlockOperation { }
    //operation2.addObserver(observer)
    operation2.name = "operation2"
    operation2.completionBlock = { expectation2.fulfill() }
    
    let group = GroupOperation()
    group.name = "group"
    group.completionBlock = { expectation5.fulfill() }
    
    let dependency1 = AdvancedBlockOperation { complete in complete([]) }
    dependency1.name = "dependency1"
    dependency1.completionBlock = { expectation3.fulfill() }
    
    let dependency2 = AdvancedBlockOperation { complete in
      sleep(1)
      complete([]) }
    dependency2.name = "dependency2"
    dependency2.completionBlock = { expectation4.fulfill() }
    
    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)
    
    operation1.addCondition(dependencyCondition1)
    operation2.addCondition(dependencyCondition2)
    
    group.addOperation(operation: operation1)
    group.addOperation(operation: operation2)
    
    group.start()
    group.cancel(error: MockError.failed)
    
    waitForExpectations(timeout: 15)
    
    XCTAssertSameErrorQuantity(errors: group.errors, expectedErrors: [MockError.failed])
    
    XCTAssertTrue(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.isFinished)
    XCTAssertTrue(operation2.isCancelled)
    XCTAssertTrue(operation2.isFinished, "🔴 \(operation2.state)")
  }
  
  func testCancelledOperationWithMultipleConditions() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = SleepyOperation()
    operation1.completionBlock = { expectation1.fulfill() }
    
    let dependency1 = AdvancedBlockOperation { complete in
      sleep(5)
      XCTAssertFalse(operation1.isExecuting)
      complete([])
    }
    dependency1.completionBlock = { expectation2.fulfill() }
    
    let dependency2 = AdvancedBlockOperation { complete in
      XCTAssertFalse(operation1.isExecuting)
      complete([])
    }
    dependency2.completionBlock = { expectation3.fulfill() }
    
    let dependency3 = AdvancedBlockOperation {
      XCTAssertFalse(operation1.isExecuting)
    }
    
    dependency3.completionBlock = {
      expectation4.fulfill()
    }
    
    let dependencyCondition1 = DependencyCondition(dependency: dependency1)
    let dependencyCondition2 = DependencyCondition(dependency: dependency2)
    let dependencyCondition3 = DependencyCondition(dependency: dependency3)
    
    operation1.addCondition(dependencyCondition1)
    operation1.addCondition(dependencyCondition2)
    operation1.addCondition(dependencyCondition3)
    
    let queue = AdvancedOperationQueue()
    queue.addOperation(operation1)
    
    operation1.cancel() // at this point: all its dependecies are already running
    
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation1.isCancelled)
  }
  
  func testCancelledOperationWhileEvaluatingConditions() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let operation1 = SleepyOperation()
    operation1.completionBlock = { expectation2.fulfill() }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
      operation1.cancel() // at this point the operation itself is cancelled, but its conditions are still evaluating
    }
    for _ in 1...100 {
      operation1.addCondition(SlowCondition())
    }
    
    let queue = AdvancedOperationQueue()
    queue.addOperation(operation1)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      
      expectation1.fulfill()
    }
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertFalse(operation1.isCancelled, "The operation is not cancelled yet because it's still evaluating some conditions.")
    XCTAssertTrue(operation1.state == .evaluating)
    
    wait(for: [expectation2], timeout: 10)
    XCTAssertTrue(operation1.isCancelled)
    XCTAssertTrue(operation1.state == .finished)
  }
  
  //    func testStress() {
  //      for i in 1...200 {
  //        print(i)
  //        testCancelledOperationWhileEvaluatingConditions()
  //      }
  //    }
  
}
