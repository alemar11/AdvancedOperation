// AdvancedOperation

import XCTest
@testable import AdvancedOperation

final class OperationUtilsTests: XCTestCase {
  override class func setUp() {
    #if swift(<5.1)
    AdvancedOperation.KVOCrashWorkaround.installFix()
    #endif
  }

  func testRemoveDependencies() {
    let operation1 = AsynchronousBlockOperation() { $0() }
    let operation2 = SleepyAsyncOperation()
    let operation3 = BlockOperation { }
    let operation4 = SleepyAsyncOperation()

    operation4.addDependencies([operation1, operation2, operation3])
    XCTAssertEqual(operation4.dependencies.count, 3)

    operation4.removeDependencies()
    XCTAssertEqual(operation4.dependencies.count, 0)
  }

  func testHasSomeDependenciesCancelled() {
    let operation1 = BlockOperation()
    let operation2 = BlockOperation()
    let operation3 = BlockOperation()
    let operation4 = BlockOperation()

    operation4.addDependencies(operation1, operation2, operation3)
    XCTAssertFalse(operation4.hasSomeCancelledDependencies)

    operation1.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)

    operation2.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)

    operation2.cancel()
    XCTAssertTrue(operation4.hasSomeCancelledDependencies)
  }

  func testAddDepedenciesToMultipleOperationsAllTogether() {
    let operation1 = BlockOperation()
    let operation2 = BlockOperation()
    let operation3 = BlockOperation()
    let operation4 = BlockOperation()
    let sequence = [operation1, operation2, operation3, operation4]
    let operation5 = BlockOperation()
    let operation6 = BlockOperation()
    let operation7 = BlockOperation()
    let operation8 = BlockOperation()
    sequence.addDependencies(operation5, operation6, operation7)

    sequence.forEach {
      XCTAssertTrue($0.dependencies.contains(operation5))
      XCTAssertTrue($0.dependencies.contains(operation6))
      XCTAssertTrue($0.dependencies.contains(operation7))
      XCTAssertTrue($0.dependencies.contains(operation7))
      XCTAssertFalse($0.dependencies.contains(operation8))
    }
  }

  func testSerialOperationQueue() {
    let queue = OperationQueue.serial()
    XCTAssertEqual(queue.maxConcurrentOperationCount, 1)
  }
}
