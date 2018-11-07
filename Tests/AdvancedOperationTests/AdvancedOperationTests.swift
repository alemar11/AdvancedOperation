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

final class AdvancedOperationTests: XCTestCase {
  
  func testStart() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.progress.isFinished)
  }
  
  func testMultipleStart() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    operation.start()
    operation.start()
    operation.start()
    
    XCTAssertTrue(operation.isExecuting)
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.progress.isFinished)
  }
  
  func testMultipleAsyncStart() {
    let queue = DispatchQueue(label: "test")
    let operation = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isExecuting), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isExecuting), object: operation, expectedValue: false)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    queue.async {
      operation.start()
    }
    operation.start()
    queue.async {
      operation.start()
    }
    
    wait(for: [expectation1, expectation2, expectation3], timeout: 10)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.progress.isFinished)
  }
  
  func testMultipleAsyncStartAndCancel() {
    let queue1 = DispatchQueue(label: "test1")
    let queue2 = DispatchQueue(label: "test2")
    let operation = SleepyAsyncOperation(interval1: 0, interval2: 1, interval3: 0)
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isExecuting), object: operation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isExecuting), object: operation, expectedValue: false)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    
    queue1.async {
      operation.start()
    }
    operation.start()
    queue2.async {
      operation.cancel()
    }
    queue1.async {
      operation.start()
    }
    
    wait(for: [expectation1, expectation2, expectation3], timeout: 10)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isCancelled)
  }
  
  func testCancel() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    operation.cancel()
    XCTAssertTrue(operation.isCancelled)
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.progress.isFinished)
  }
  
  func testCancelWithoutStarting() {
    let operation = SleepyAsyncOperation()
    
    XCTAssertTrue(operation.isReady)
    let expectation = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation, expectedValue: true)
    operation.cancel()
    
    wait(for: [expectation], timeout: 10)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)
    XCTAssertFalse(operation.progress.isFinished)
  }
  
  func testCancelBeforeStart() {
    let operation = SleepyAsyncOperation(interval1: 1, interval2: 1, interval3: 1)
    XCTAssertTrue(operation.isReady)
    
    operation.cancel()
    operation.start()
    XCTAssertTrue(operation.isCancelled)
    
    operation.waitUntilFinished()
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testMultipleCancel() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    operation.cancel()
    operation.cancel(errors: [MockError.test])
    operation.cancel(errors: [MockError.failed])
    XCTAssertTrue(operation.isCancelled)
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.progress.isFinished)
  }
  
  func testMultipleCancelWithManyObservers() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    
    for _ in 1...100 {
      operation.addObserver(BlockObserver())
    }
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    let queue = DispatchQueue(label: "test")
    
    operation.cancel()
    
    queue.async {
      operation.cancel(errors: [MockError.test])
    }
    operation.cancel(errors: [MockError.failed])
    XCTAssertTrue(operation.isCancelled)
    
    wait(for: [expectation1], timeout: 10)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testMultipleStartsAndCancels() {
    let operation = RunUntilCancelledAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    operation.cancel()
    operation.start()
    operation.cancel(errors: [MockError.test])
    operation.cancel(errors: [MockError.failed])
    
    wait(for: [expectation1], timeout: 10)
    
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.hasErrors)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
  }
  
  func testMultipleStartAndCancelWithErrors() {
    let operation = RunUntilCancelledAsyncOperation(queue: .main)
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    operation.useOSLog(TestsLog)
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    operation.cancel(errors: [MockError.test])
    operation.start()
    operation.cancel()
    operation.cancel(errors: [MockError.failed])
    
    wait(for: [expectation1], timeout: 10)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [MockError.test])
  }
  
  func testMultipleCancelWithError() {
    let operation = RunUntilCancelledAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    XCTAssertTrue(operation.isReady)
    
    operation.start()
    XCTAssertTrue(operation.isExecuting)
    
    let error = MockError.cancelled(date: Date())
    operation.cancel(errors: [error])
    operation.cancel(errors: [MockError.test])
    operation.cancel(errors: [MockError.failed])
    XCTAssertTrue(operation.isCancelled)
    
    wait(for: [expectation1], timeout: 10)
    
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [error])
  }
  
  func testObservers() {
    let observer = MockObserver()
    let expectation2 = observer.didFinishExpectation
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer)
    
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    operation.start()
    operation.start()
    
    wait(for: [expectation1, expectation2], timeout: 10)
    
    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.willFinishCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willCancelCount, 0)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
  }
  
  func testObserversWithMultipleCancelCommands() {
    let observer = MockObserver()
    let operation = RunUntilCancelledAsyncOperation()
    operation.addObserver(observer)
    
    let expectation1 = keyValueObservingExpectation(for: operation, keyPath: #keyPath(AdvancedOperation.isFinished)) { (operation, changes) -> Bool in
      if let operation = operation as? AdvancedOperation {
        return operation.isFinished
      }
      return false
    }
    
    let expectation2 = observer.didFinishExpectation
    
    operation.start()
    operation.cancel()
    operation.cancel(errors: [MockError.cancelled(date: Date())])
    
    wait(for: [expectation1, expectation2], timeout: 10)
    
    XCTAssertEqual(observer.willExecutetCount, 1, "willExecutetCount should be called 1 time instead of \(observer.willExecutetCount)")
    
    XCTAssertEqual(observer.willCancelCount, 1, "willCancelCount should be called 1 time instead of \(observer.willCancelCount)")
    XCTAssertEqual(observer.didCancelCount, 1, "didCancelCount should be called 1 time instead of \(observer.didCancelCount)")
    
    XCTAssertEqual(observer.willFinishCount, 1, "willFinishCount should be called 1 time instead of \(observer.willFinishCount)")
    XCTAssertEqual(observer.didFinishCount, 1, "didFinishCount should be called 1 time instead of \(observer.didFinishCount)")
    
    XCTAssertEqual(operation.errors.count, 0)
  }
  
  func testObserversWithOperationProduction() {
    let operation = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    let observer = MockObserver()
    let expectation2 = observer.didFinishExpectation
    
    operation.addObserver(observer)
    
    operation.produceOperation(BlockOperation { })
    operation.produceOperation(BlockOperation { })
    operation.start()
    
    wait(for: [expectation1, expectation2], timeout: 10)
    
    XCTAssertEqual(observer.willExecutetCount, 1)
    XCTAssertEqual(observer.didProduceCount, 2)
    XCTAssertEqual(observer.willFinishCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(observer.willCancelCount, 0)
    XCTAssertEqual(observer.didCancelCount, 0)
    XCTAssertEqual(operation.errors.count, 0)
  }
  
  func testCancelWithErrors() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let operation = SleepyAsyncOperation()
    
    operation.completionBlock = { expectation1.fulfill() }
    operation.start()
    
    XCTAssertTrue(operation.isExecuting)
    
    operation.cancel(errors: [MockError.test])
    XCTAssertTrue(operation.isCancelled)
    
    waitForExpectations(timeout: 10)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertSameErrorQuantity(errors: operation.errors, expectedErrors: [MockError.test])
  }
  
  func testFinishWithErrors() {
    let operation = FailingAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    
    operation.start()
    
    wait(for: [expectation1], timeout: 10)
    XCTAssertEqual(operation.errors.count, 2)
  }
  
  // The readiness of operations is determined by their dependencies on other operations and potentially by custom conditions that you define.
  func testReadiness() {
    // Given
    let operation1 = SleepyAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation1, expectedValue: true)
    XCTAssertTrue(operation1.isReady)
    
    let operation2 = BlockOperation(block: { } )
    let expectation2 = expectation(description: "\(#function)\(#line)")
    operation2.addExecutionBlock { expectation2.fulfill() }
    
    // When
    operation1.addDependency(operation2)
    XCTAssertFalse(operation1.isReady)
    
    // Then
    operation2.start()
    XCTAssertTrue(operation1.isReady)
    operation1.start()
    
    wait(for: [expectation1, expectation2], timeout: 10)
    
    XCTAssertTrue(operation1.isFinished)
  }
  
  func testSubclassableObservers() {
    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")
    let expectation5 = expectation(description: "\(#function)\(#line)")
    let expectation6 = expectation(description: "\(#function)\(#line)")
    
    let operation1 = SelfObservigOperation()
    let operation2 = AdvancedBlockOperation { }
    let error = MockError.test
    
    operation1.willExecuteHandler = {
      expectation1.fulfill()
    }
    
    operation1.didProduceOperationHandler = { operation in
      XCTAssertTrue(operation2 === operation)
      expectation2.fulfill()
    }
    
    operation1.willCancelHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation3.fulfill()
    }
    
    operation1.didCancelHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation4.fulfill()
    }
    
    operation1.willFinishHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation5.fulfill()
    }
    
    operation1.didFinishHandler = { errors in
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors.count, 1)
      expectation6.fulfill()
    }
    
    operation1.start()
    operation1.produceOperation(operation2)
    operation1.cancel(errors: [error])
    waitForExpectations(timeout: 10)
  }
  
  func testSynchronousOperationFinishedWithoutErrors() {
    let operation = SynchronousOperation(errors: [])
    operation.start()
    XCTAssertTrue(operation.isFinished)
  }
  
  func testSynchronousOperationFinishedWithErrors() {
    let operation = SynchronousOperation(errors: [MockError.failed])
    operation.start()
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.hasErrors)
  }
  
  func testProgress() {
    let operation = ProgressOperation()
    let token = operation.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.localizedDescription) //TODO add expectation or assert
    }
    operation.start()
    XCTAssertTrue(operation.progress.isFinished)
    token.invalidate()
  }

  func testCancelledProgress() {
    var units = [Int64]()
    var fractions = [Double]()
    let operation = ProgressOperation()
    let token = operation.progress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.localizedDescription)
      fractions.append(progress.fractionCompleted)
      units.append(progress.completedUnitCount)
    }
    operation.progress.cancel()
    operation.start()
    XCTAssertTrue(operation.isFinished)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.progress.isFinished)
    XCTAssertEqual(units, [1])
    XCTAssertEqual(fractions, [1.0])
    token.invalidate()
  }
  
  func testImplicitProgress() {
    var units = [Int64]()
    var fractions = [Double]()
    let currentProgress = Progress(totalUnitCount: 1)
    currentProgress.becomeCurrent(withPendingUnitCount: 1)
    let currentToken = currentProgress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.localizedDescription)
      fractions.append(progress.fractionCompleted)
      units.append(progress.completedUnitCount)
    }
    let operation = ProgressOperation()
    operation.start()
    currentProgress.resignCurrent()
    XCTAssertTrue(operation.progress.isFinished)
    XCTAssertTrue(currentProgress.isFinished)
    XCTAssertEqual(units, [0, 0, 0, 1])
     XCTAssertEqual(fractions, [0.3, 0.6, 0.9, 1.0])
    currentToken.invalidate()
  }
  
  func testExplicitProgress() {
    var units = [Int64]()
    var fractions = [Double]()
    let currentProgress = Progress(totalUnitCount: 1)
    let operation = ProgressAsyncOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation, expectedValue: true)
    currentProgress.addChild(operation.progress, withPendingUnitCount: 1)
    let token = currentProgress.observe(\.fractionCompleted, options: [.new]) { (progress, change) in
      print(progress.localizedDescription)
      fractions.append(progress.fractionCompleted)
      units.append(progress.completedUnitCount)
    }
    operation.start()
    wait(for: [expectation1], timeout: 10)
    XCTAssertTrue(operation.progress.isFinished)
    XCTAssertTrue(currentProgress.isFinished)
    XCTAssertEqual(units, [0, 0, 0, 1])
    XCTAssertEqual(fractions, [0.3, 0.6, 0.9, 1.0])
    token.invalidate()
  }
  
}
