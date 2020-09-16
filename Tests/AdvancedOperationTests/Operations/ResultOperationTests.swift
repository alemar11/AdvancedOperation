// AdvancedOperation

import XCTest
@testable import AdvancedOperation

final class ResultOperationTests: XCTestCase {
  func testCancelBeforeExecuting() {
    let operation = DummyResultOperation()
    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    operation.onFinish = { result in
      switch result {
      case .failure(let error) where error == .cancelled:
        resultProducedExpectation.fulfill()
      default:
        XCTFail("Expected a cancelled error.")
      }
    }
    operation.cancel()
    //    DispatchQueue.global().asyncAfter(deadline: .now()) {
    //      operation.cancel()
    //    }
    operation.start()
    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  }

  func testEarlyBailOutWithoutResult() {
    let operation = DummyResultOperation(setFailureOnEarlyBailOut: false)
    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)

    operation.onFinish = { result in
      XCTAssertNil(result)
      resultProducedExpectation.fulfill()
    }
    operation.cancel()
    operation.start()
    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  }

  //  func testFinishBeforeExecuting() {
  //    let operation = DummyResultOperation()
  //    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
  //    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
  //    operation.onFinish = { result in
  //      switch result {
  //      case .failure(let error) where error == .cancelled:
  //        resultProducedExpectation.fulfill()
  //      default:
  //        XCTFail("Expected a cancelled error.")
  //      }
  //    }
  //    operation.cancel()
  //    operation.finish() // ⚠️ finish() must not for any reason called outside the main() scope
  //    operation.start()
  //    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  //  }

  func testSuccessFulExecution() {
    let queue = OperationQueue()
    let operation = DummyResultOperation()
    let resultProducedExpectation = XCTestExpectation(description: "Result Produced")
    let finishExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation, expectedValue: true)
    operation.onFinish = { result in
      switch result {
      case .success(let value) where value == "Success":
        resultProducedExpectation.fulfill()
      default:
        XCTFail(#"Expected a "Success" value."#)
      }
    }
    queue.addOperation(operation)
    wait(for: [resultProducedExpectation, finishExpectation], timeout: 2)
  }
}
