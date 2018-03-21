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

import Foundation
import Dispatch
import XCTest
@testable import AdvancedOperation

// MARK: - Error

internal enum MockError: Swift.Error, Equatable {
  case test
  case failed
  case cancelled(date: Date)
  case generic(date: Date)

  static func ==(lhs: MockError, rhs: MockError) -> Bool {
    switch (lhs, rhs) {
    case (.test, .test):
      return true
    case (.failed, .failed):
      return true
    case (let .cancelled(dateLhs), let .cancelled(dateRhs)):
      return dateLhs == dateRhs
    case (let .generic(dateLhs), let .generic(dateRhs)):
      return dateLhs == dateRhs
    default:
      return false
    }
  }
}

// MARK: - AdvancedOperation

final internal class SleepyAsyncOperation: AdvancedOperation {

  private let interval1: UInt32
  private let interval2: UInt32
  private let interval3: UInt32

  init(interval1: UInt32 = 1, interval2: UInt32 = 2, interval3: UInt32 = 1) {
    self.interval1 = interval1
    self.interval2 = interval2
    self.interval3 = interval3
    super.init()
  }

  override func main() {

    DispatchQueue.global().async { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else { return self.finish() }
      if strongSelf.isCancelled {
        strongSelf.finish()
        return
      }

      sleep(self.interval1)
      if strongSelf.isCancelled {
        strongSelf.finish()
        return
      }

      sleep(self.interval2)
      if strongSelf.isCancelled {
        strongSelf.finish()
        return
      }

      sleep(self.interval3)
      strongSelf.finish()
    }

  }

}

final internal class SleepyOperation: AdvancedOperation {

  override func main() {
    sleep(1)
    self.finish()
  }

}

final internal class XCTFailOperation: AdvancedOperation {

  override func main() {
    XCTFail("This operation should't be executed.")
    self.finish()
  }

}

final internal class FailingAsyncOperation: AdvancedOperation {

  private let defaultErrors: [Error]

  init(errors: [MockError] = [MockError.failed, MockError.test]) {
    self.defaultErrors = errors
    super.init()
  }

  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else { return self.finish() }
      strongSelf.finish(errors: strongSelf.defaultErrors)
    }
  }
}

// MARK: - OperationObserving

final internal class MockObserver: OperationObserving {

  var identifier = UUID().uuidString
  var willExecutetCount = 0
  var didFinishCount = 0
  var didCancelCount = 0

  func operationWillExecute(operation: Operation) {
    assert(operation.isExecuting)
    willExecutetCount += 1
  }

  func operationDidFinish(operation: Operation, withErrors errors: [Error]) {
    assert(operation.isFinished)
    didFinishCount += 1
  }

  func operationDidCancel(operation: Operation, withErrors errors: [Error]) {
    assert(operation.isCancelled)
    didCancelCount += 1
  }

}

// MARK: - AdvancedOperationQueueDelegate

final internal class MockOperationQueueDelegate: AdvancedOperationQueueDelegate {

  var willAddOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var didAddOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil

  var willExecuteOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var didFinishOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  var didCancelOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil

  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    self.willAddOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {
    self.didAddOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: Operation) {
    self.willExecuteOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
    self.didFinishOperationHandler?(operationQueue, operation, errors)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: Operation, withErrors errors: [Error]) {
    self.didCancelOperationHandler?(operationQueue, operation, errors)
  }

}
