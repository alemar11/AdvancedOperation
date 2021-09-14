// TaskOperationTests

import XCTest
@testable import AdvancedOperation

@available(swift 5.5)
@available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *)
final class TaskOperationTests: XCTestCase {
  func testExecution() {
    let expection1 = expectation(description: "\(#function)\(#line)")
    @Sendable func test() async -> Void { expection1.fulfill() }
    let operation = TaskOperation {
      await test()
    }
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.start()
    wait(for: [expection1, finishExpectation], timeout: 2)
  }
  
  func testExecutionInQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 2
    queue.isSuspended = true
    let expection1 = expectation(description: "\(#function)\(#line)")
    @Sendable func test() async -> Void { expection1.fulfill() }
    let operation = TaskOperation {
      await test()
    }
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    queue.isSuspended = false
    wait(for: [expection1, finishExpectation], timeout: 2)
  }
  
  func testCancel() {
    let operation = TaskOperation { XCTFail("The underlying task should be cancelled.") }
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [finishExpectation], timeout: 2)
  }
  
  func testCancelInQueue() {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 2
    queue.isSuspended = true
    let operation = TaskOperation { XCTFail("The underlying task should be cancelled.") }
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    queue.cancelAllOperations()
    queue.isSuspended = false
    wait(for: [finishExpectation], timeout: 2)
  }
}
