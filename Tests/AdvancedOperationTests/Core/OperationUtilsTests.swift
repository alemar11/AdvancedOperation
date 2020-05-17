//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testExplicitProgressUsingGroupOperationWithInternalSerialQueue() {
    let currentProgress = Progress(totalUnitCount: 1)

    let operation1 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation3 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation2 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation4 = BlockOperation { sleep(1) }

    let expectation0 = self.expectation(description: "Progress is completed")
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3, operation4])

    currentProgress.addChild(groupOperation.progress, withPendingUnitCount: 1)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    groupOperation.maxConcurrentOperationCount = 1 // TODO, test with a concurrent group operation too
    groupOperation.start()
    wait(for: [expectation1, expectation2, expectation3, expectation4, expectation0], timeout: 10)
    token.invalidate()
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testExplicitProgressUsingGroupOperationAndOperationQueue() {
    let queue = OperationQueue()
    let currentProgress = Progress(totalUnitCount: 1)

    let operation1 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation3 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation2 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation4 = BlockOperation { sleep(1) }

    let expectation0 = self.expectation(description: "Progress is completed")
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3, operation4])

    currentProgress.addChild(queue.progress, withPendingUnitCount: 1)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    groupOperation.maxConcurrentOperationCount = 1
    queue.progress.totalUnitCount = 1
    queue.addOperation(groupOperation)

    wait(for: [expectation1, expectation2, expectation3, expectation4, expectation0], timeout: 10)
    token.invalidate()
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testExplicitProgressUsingSerialQueue() {
    // AsyncOperation implementation needs to call super.start() in order to enable progress reporting
    // even if the Operation documentation says to not call super.start()
    let currentProgress = Progress(totalUnitCount: 1)
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.isSuspended = true

    // -[NSProgress addChild:withPendingUnitCount:]
    // po ((_NSOperationQueueProgress*)$arg1)->_queue
    // for operation4:
    // po ((NSBlockOperation*)((NSOperationQueue*)((_NSOperationQueueProgress*)$arg1)->_queue).operations[0])

    //    let operation1 = BlockOperation { sleep(1); print("operation 1 executed") }
    //    let operation2 = BlockOperation { sleep(1); print("operation 2 executed") }
    //    let operation3 = BlockOperation { sleep(1); print("operation 3 executed") }

    let operation1 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation3 = AsyncBlockOperation { complete in
      sleep(1)
      complete()
    }

    let operation2 = AsyncBlockOperation { complete in
      sleep(1)
      // if we cancel an operation we need to be sure to reduce the progress totalUnitCount
      //OperationQueue.current?.progress.totalUnitCount -= 1
      //operation3.cancel()
      complete()
    }

    let operation4 = BlockOperation { sleep(1); print("operation 4 executed") }

    let expectation0 = self.expectation(description: "Progress is completed")
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)

    queue.progress.totalUnitCount = 4
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)

    currentProgress.addChild(queue.progress, withPendingUnitCount: 1)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    queue.isSuspended = false
    wait(for: [expectation1, expectation2, expectation3, expectation4, expectation0], timeout: 10)
    token.invalidate()
  }
}


/**
cancel group operation and start

 cancel while running

 added cancelled operation

 symbolic bp NSProgress alloc init

 */
