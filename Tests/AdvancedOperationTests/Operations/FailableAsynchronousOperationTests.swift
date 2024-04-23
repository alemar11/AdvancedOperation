// AdvancedOperation

import XCTest

@testable import AdvancedOperation

final class FailableAsynchronousOperationTests: XCTestCase {
  func testCancelBeforeExecuting() {
    let operation = DummyFailableOperation(shouldFail: true)
    let finishExpectation = XCTKVOExpectation(
      keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.cancel()
    operation.start()
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertEqual(operation.error, DummyFailableOperation.Error.cancelled)
  }

  //  func testFinishBeforeExecuting() {
  //    let operation = DummyFailableOperation(shouldFail: false)
  //    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
  //    //operation.cancel()
  //    operation.finish() // ⚠️ finish() must not for any reason called outside the main() scope
  //    wait(for: [finishExpectation], timeout: 2)
  //  }

  func testSuccessFulExecution() {
    let queue = OperationQueue()
    let operation = DummyFailableOperation(shouldFail: false)
    let finishExpectation = XCTKVOExpectation(
      keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertNil(operation.error)
  }

  func testFailedExecution() {
    let queue = OperationQueue()
    let operation = DummyFailableOperation(shouldFail: true)
    let finishExpectation = XCTKVOExpectation(
      keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    queue.addOperation(operation)
    wait(for: [finishExpectation], timeout: 2)
    XCTAssertEqual(operation.error, DummyFailableOperation.Error.failed)
  }

  func testChainFailedExecution() {
    let queue = OperationQueue()
    let operation1 = BlockOperation()
    let operation2 = DummyFailableOperation(shouldFail: false)
    let adapter = BlockOperation { [unowned operation2] in
      operation2.cancel(with: .other)
    }
    adapter.addDependency(operation1)
    operation2.addDependency(adapter)
    queue.addOperations([operation1, operation2, adapter], waitUntilFinished: true)
    XCTAssertEqual(operation2.error, DummyFailableOperation.Error.other)
  }
}
