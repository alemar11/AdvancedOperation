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
//
// https://developer.apple.com/videos/play/wwdc2015/232/

import XCTest
@testable import AdvancedOperation

final class ProgressReportingTests: XCTestCase {

//  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
//  func testAddingOperationsWhileGroupOperationIsExecuting() {
//    let currentProgress = Progress(totalUnitCount: 1)
//    let operation1 = InfiniteAsyncOperation()
//    let groupOperation = GroupOperation(operations: [operation1])
//    let operation2 = AsyncBlockOperation { complete in
//      sleep(1)
//      complete()
//    }
//    let operation3 = BlockOperation { [unowned operation1] in
//      sleep(1)
//      operation1.stop()
//    }
//
//    operation1.onExecutionStarted = { [unowned groupOperation] in
//      groupOperation.addOperation(operation2)
//      groupOperation.addOperation(BlockOperation())
//      groupOperation.addOperation(BlockOperation())
//      groupOperation.addOperation(BlockOperation())
//      groupOperation.addOperation(BlockOperation())
//      groupOperation.addOperation(operation3)
//    }
//
//    currentProgress.addChild(groupOperation.progress, withPendingUnitCount: 1)
//
//    let expectation0 = self.expectation(description: "Progress is completed")
//    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
//      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")
//
//      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
//        expectation0.fulfill()
//      }
//    }
//
//    groupOperation.maxConcurrentOperationCount = 3
//    groupOperation.start()
//    wait(for: [expectation0], timeout: 5)
//    token.invalidate()
//  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testProgressReportingWhenAddingCancelledOperationToGroupOperation() {
    let currentProgress = Progress(totalUnitCount: 1)
    let operation1 = AsyncBlockOperation { $0() }
    let operation2 = BlockOperation { }
    let operation3 = BlockOperation { }

    // When added to the GroupOperation, since it's cancelled it won't increase the internal queue progress totalUnitCount
    operation1.cancel()

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3])

    currentProgress.addChild(groupOperation.progress, withPendingUnitCount: 1)

    let expectation0 = self.expectation(description: "Progress is completed")
    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    groupOperation.maxConcurrentOperationCount = 1
    groupOperation.start()
    wait(for: [expectation0], timeout: 5)
    token.invalidate()
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testProgressReportingWhenAddingOperationWhileGroupOperationIsBeingCancelled() {
    let currentProgress = Progress(totalUnitCount: 1)
    let operation1 = RunUntilCancelledAsyncOperation()
    let operation2 = SleepyAsyncOperation(interval1: 1, interval2: 0, interval3: 0)
    let operation3 = InfiniteAsyncOperation()
    let operation4 = CancelledOperation()

    operation1.name = "op1"
    operation2.name = "op2"
    operation3.name = "op3"
    operation4.name = "op4"

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3])

    // cancellation is done while at least one operation is running
    operation3.onExecutionStarted = { [unowned groupOperation] in
      print("cancelling group")
      groupOperation.cancel()
      groupOperation.addOperation(operation4)
    }

    operation4.completionBlock = { [unowned operation3] in
      operation3.stop()
    }

    let expectation0 = self.expectation(description: "Progress is completed")
    expectation0.assertForOverFulfill = false // groupOperation has a concurrent queue
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: groupOperation, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)

    currentProgress.addChild(groupOperation.progress, withPendingUnitCount: 1)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    groupOperation.start()
    wait(for: [expectation0, expectation1, expectation2], timeout: 5)
    token.invalidate()
  }


  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testProgressReportingGroupOperationCancelledBeforeStarting() {
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
    //    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
    //    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation2, expectedValue: true)
    //    let expectation3 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation3, expectedValue: true)
    //    let expectation4 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation4, expectedValue: true)

    let groupOperation = GroupOperation(operations: [operation1, operation2, operation3, operation4])

    currentProgress.addChild(groupOperation.progress, withPendingUnitCount: 1)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    groupOperation.maxConcurrentOperationCount = 1
    groupOperation.cancel()
    groupOperation.start()
    wait(for: [expectation0], timeout: 3)
    token.invalidate()
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testProgressReportingGroupOperationHavingAnInternalSerialQueue() {
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

    groupOperation.maxConcurrentOperationCount = 1
    groupOperation.start()
    wait(for: [expectation1, expectation2, expectation3, expectation4, expectation0], timeout: 10)
    token.invalidate()
  }

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testProgressReportingWhenGroupOperationRunInAnOperationQueue() {
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
      OperationQueue.current?.progress.totalUnitCount -= 1
      operation3.cancel()
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

  @available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  func testImplicitProgressUsingSerialQueue() {
    let currentProgress = Progress(totalUnitCount: 1)

    // ➡️ the rule of thumb for implicit progress is to call becomeCurrent() and resignCurrent() as closely a possible around the code which you want to track.
    // ➡️ Note: Only the first progress attached to the parent during that window will be tracked; the rest will be ignored.
    currentProgress.becomeCurrent(withPendingUnitCount: 1)
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.isSuspended = true

    let operation1 = AsyncBlockOperation { $0() }
    let operation3 = AsyncBlockOperation { $0() }
    let operation2 = AsyncBlockOperation { $0() }
    let operation4 = BlockOperation { sleep(1); print("operation 4 executed") }
    let expectation0 = self.expectation(description: "Progress is completed")

    queue.progress.totalUnitCount = 4
    queue.addOperation(operation1)
    queue.addOperation(operation2)
    queue.addOperation(operation3)
    queue.addOperation(operation4)

    let token = currentProgress.observe(\.fractionCompleted, options: [.initial, .old, .new]) { (progress, change) in
      print(progress.fractionCompleted, progress.localizedAdditionalDescription ?? "")

      if progress.completedUnitCount == 1 && progress.fractionCompleted == 1.0 {
        expectation0.fulfill()
      }
    }

    queue.isSuspended = false
    // ➡️ resign immediately when the queue resumes work
    currentProgress.resignCurrent()
    wait(for: [expectation0], timeout: 10)
    token.invalidate()
  }
}


/**

 symbolic bp NSProgress alloc init

 */


