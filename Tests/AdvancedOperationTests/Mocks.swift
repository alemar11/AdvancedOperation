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

import Foundation
import Dispatch
import XCTest
import os.log
@testable import AdvancedOperation

// MARK: - OsLog

let TestsLog = OSLog(subsystem: identifier, category: "Tests")

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

// MARK: - Operation

class SimpleOperation: Operation {

  override func main() {
    if isCancelled {
      return
    }
    sleep(2)
  }
}

// MARK: - AdvancedOperation

final internal class SelfObservigOperation: AdvancedOperation {

  var willExecuteHandler: (() -> Void)? = nil
  var didProduceOperationHandler: ((Operation) -> Void)? = nil
  var willCancelHandler: (([Error]) -> Void)? = nil
  var didCancelHandler: (([Error]) -> Void)? = nil
  var willFinishHandler: (([Error]) -> Void)? = nil
  var didFinishHandler: (([Error]) -> Void)? = nil

  override init() {
    super.init()
  }

  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
      guard let self = self else { return }
      if `self`.isCancelled {
        self.finish()
        return
      }
      self.finish()
    }

  }

  override func operationWillExecute() {
    willExecuteHandler?()
  }

  override func operationWillCancel(errors: [Error]) {
    willCancelHandler?(errors)
  }

  override func operationDidProduceOperation(_ operation: Operation) {
    didProduceOperationHandler?(operation)
  }

  override func operationDidCancel(errors: [Error]) {
    didCancelHandler?(errors)
  }

  override func operationWillFinish(errors: [Error]) {
    willFinishHandler?(errors)
  }

  override func operationDidFinish(errors: [Error]) {
    didFinishHandler?(errors)
  }

}

final internal class SynchronousOperation: AdvancedOperation {
  override var isAsynchronous: Bool { return false }
  let finishingErrors: [Error]

  init(errors: [Error] = []) {
    self.finishingErrors = errors
  }

  override func main() {
    if isCancelled {
      return
    }

    if !finishingErrors.isEmpty {
      finish(errors: finishingErrors)
    }

    // There's no need to call finish if we don't need to register errors upon completion.
  }

}

final internal class InfiniteAsyncOperation: AdvancedOperation {
  let queue: DispatchQueue

  init(queue: DispatchQueue = DispatchQueue.global()) {
    self.queue = queue
  }

  override func main() {
    queue.async {
      while true {
        // infinite
      }
    }
  }
}

final internal class RunUntilCancelledAsyncOperation: AdvancedOperation {
  let queue: DispatchQueue

  init(queue: DispatchQueue = DispatchQueue.global()) {
    self.queue = queue
  }

  override func main() {
    queue.async {
      while !self.isCancelled {
        sleep(1)
      }
      self.finish()
    }
  }
}

final internal class SleepyAsyncOperation: AdvancedOperation {

  private let interval1: UInt32
  private let interval2: UInt32
  private let interval3: UInt32

  init(interval1: UInt32 = 1, interval2: UInt32 = 1, interval3: UInt32 = 1) {
    self.interval1 = interval1
    self.interval2 = interval2
    self.interval3 = interval3
    super.init()
  }

  override func main() {
    DispatchQueue.global().async { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else {
        self.finish()
        return
      }

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

  override var isAsynchronous: Bool { return false }
  private let interval: UInt32

  init(interval: UInt32 = 1) {
    self.interval = interval
    super.init()
  }

  override func main() {
    sleep(interval)
  }

}

final internal class SleepyBlockOperation: AdvancedOperation {

  override public var isAsynchronous: Bool { return false }
  let block: () -> Void
  let interval: UInt32

  init(interval: UInt32, block: @escaping () -> Void) {
    self.block = block
    self.interval = interval
    super.init()
  }

  override func main() {
    sleep(self.interval)
    block()
  }

}

final internal class NotExecutableOperation: AdvancedOperation {

  override public var isAsynchronous: Bool { return false }

  override func main() {
    if isCancelled {
      return
    }

    XCTFail("This operation shouldn't be executed.")
  }

}

/// An operation that finishes with errors
final internal class FailingAsyncOperation: AdvancedOperation {

  private let defaultErrors: [Error]

  init(errors: [MockError] = [MockError.failed, MockError.test]) {
    self.defaultErrors = errors
  }

  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else {
        self.finish()
        return
      }
      strongSelf.finish(errors: strongSelf.defaultErrors)
    }
  }
}

/// An operation that check if its current operation queue is the same passed durinig its initialization.
final internal class OperationReferencingOperationQueue: AdvancedOperation {
  weak var queue: AdvancedOperationQueue? = .none

  override public var isAsynchronous: Bool { return false }

  init(queue: AdvancedOperationQueue) {
    self.queue = queue
  }

  override func main() {
    XCTAssertTrue(operationQueue === queue)
    XCTAssertTrue(operationQueue !== OperationQueue.main)
    XCTAssertTrue(queue !== OperationQueue.main)
  }
}

/// An operation that cancels itself with errors
final internal class CancellingAsyncOperation: AdvancedOperation {

  private let defaultErrors: [Error]

  init(errors: [MockError] = [MockError.failed, MockError.test]) {
    self.defaultErrors = errors
    super.init()
  }

  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else {
        self.finish()
        return
      }

      strongSelf.cancel(errors: strongSelf.defaultErrors)
      strongSelf.finish()
    }
  }
}

/// An operation that produces another operation
final internal class ProducingOperation: AdvancedOperation {
  override public var isAsynchronous: Bool { return false }
  let operation: AdvancedOperation
  let indipendent: Bool
  let time: UInt32

  init(operation: AdvancedOperation, indipendent: Bool = true, waitingTimeOnceOperationProduced time: UInt32 = 0) {
    self.operation = operation
    self.indipendent = indipendent
    self.time = time
    super.init()
  }

  override func main() {
    guard !isCancelled else {
      return
    }

    produceOperation(operation, asIndipendentOperation: indipendent)
    sleep(time)
  }

}

final internal class ProgressOperation: AdvancedOperation {

  override public var isAsynchronous: Bool { return false }

  override func main() {
    guard !isCancelled else {
      return
    }
    progress.totalUnitCount = 10

    // 30%
    guard !isCancelled else {
      return
    }
    sleep(1)
    progress.completedUnitCount = 3

    // 60%
    guard !isCancelled else {
      return
    }
    sleep(1)
    progress.completedUnitCount = 6

    // 90%
    guard !isCancelled else {
      return
    }
    sleep(1)
    progress.completedUnitCount = 9
  }
}

final internal class ProgressAsyncOperation: AdvancedOperation {

  override func main() {
    guard !isCancelled else {
      finish()
      return
    }
    DispatchQueue.global().async { [weak self] in
      guard let self = self else {
        return
      }

      guard !self.isCancelled else {
        self.finish()
        return
      }
      self.progress.totalUnitCount = 10

      // 30%
      guard !self.isCancelled else {
        self.finish()
        return
      }
      sleep(1)
      self.progress.completedUnitCount = 3

      // 60%
      guard !self.isCancelled else {
        self.finish()
        return
      }
      sleep(1)
      self.progress.completedUnitCount = 6

      // 390%
      guard !self.isCancelled else {
        self.finish()
        return
      }

      sleep(1)
      self.progress.completedUnitCount = 9
      self.finish()
    }
  }
}

// MARK: - OperationObserving

final internal class MockObserver: OperationObserving {

  let lock = NSLock()
  var _willExecutetCount = 0
  var _didProduceCount = 0
  var _willFinishCount = 0
  var _didFinishCount = 0
  var _willCancelCount = 0
  var _didCancelCount = 0

  /// This expectation gets fulfilled after the operationDidFinish(operation:errors:) is called.
  /// - Note: The operation `completionBlock` is called before this expecations is fulfilled.
  let didFinishExpectation = XCTestExpectation(description: "finishExpectation")

  var willExecutetCount: Int {
    get {
      return lock.synchronized { return _willExecutetCount }
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _willExecutetCount = newValue
    }
  }

  var didProduceCount: Int {
    get {
      return lock.synchronized { return _didProduceCount }
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _didProduceCount = newValue
    }
  }

  var willFinishCount: Int {
    get {
      return lock.synchronized { return _willFinishCount }
    }
    set {
      lock.synchronized {
        _willFinishCount = newValue
      }
    }
  }

  var didFinishCount: Int {
    get {
      return lock.synchronized { return _didFinishCount }
    }
    set {
      lock.synchronized {
        _didFinishCount = newValue
      }
    }
  }

  var willCancelCount: Int {
    get {
      return lock.synchronized { return _willCancelCount }
    }
    set {
      lock.synchronized {
        _willCancelCount = newValue
      }
    }
  }

  var didCancelCount: Int {
    get {
      return lock.synchronized { return _didCancelCount }
    }
    set {
      lock.synchronized {
        _didCancelCount = newValue
      }
    }
  }

  func operationWillExecute(operation: AdvancedOperation) {
    assert(operation.isExecuting)
    XCTAssertEqual(willExecutetCount, 0)
    willExecutetCount += 1
  }

  func operationWillFinish(operation: AdvancedOperation, withErrors errors: [Error]) {
    assert(!operation.isFinished)
    XCTAssertEqual(willFinishCount, 0)
    willFinishCount += 1
  }

  func operationDidFinish(operation: AdvancedOperation, withErrors errors: [Error]) {
    assert(operation.isFinished)
    XCTAssertEqual(willFinishCount, 1)
    XCTAssertEqual(didFinishCount, 0)
    didFinishCount += 1
    didFinishExpectation.fulfill()
  }

  func operationWillCancel(operation: AdvancedOperation, withErrors errors: [Error]) {
    assert(!operation.isFinished)
    XCTAssertEqual(willCancelCount, 0)
    willCancelCount += 1
  }

  func operationDidCancel(operation: AdvancedOperation, withErrors errors: [Error]) {
    assert(operation.isCancelled)
    XCTAssertEqual(willCancelCount, 1)
    XCTAssertEqual(didCancelCount, 0)
    didCancelCount += 1
  }

  func operation(operation: AdvancedOperation, didProduce: Operation, asIndipendentOperation indipendent: Bool) {
    XCTAssertEqual(willExecutetCount, 0)
    didProduceCount += 1
  }

}

// MARK: - AdvancedOperationQueueDelegate

final internal class MockOperationQueueDelegate: AdvancedOperationQueueDelegate {

  var willAddOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil
  var didAddOperationHandler: ((AdvancedOperationQueue, Operation) -> Void)? = nil

  var willExecuteOperationHandler: ((AdvancedOperationQueue, AdvancedOperation) -> Void)? = nil
  var willFinishOperationHandler: ((AdvancedOperationQueue, AdvancedOperation, [Error]) -> Void)? = nil
  var didFinishOperationHandler: ((AdvancedOperationQueue, Operation, [Error]) -> Void)? = nil
  var willCancelOperationHandler: ((AdvancedOperationQueue, AdvancedOperation, [Error]) -> Void)? = nil
  var didCancelOperationHandler: ((AdvancedOperationQueue, AdvancedOperation, [Error]) -> Void)? = nil

  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) {
    self.willAddOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation) {
    self.didAddOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: AdvancedOperation) {
    self.willExecuteOperationHandler?(operationQueue, operation)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: AdvancedOperation, withErrors errors: [Error]) {
    self.willFinishOperationHandler?(operationQueue, operation, errors)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error]) {
    self.didFinishOperationHandler?(operationQueue, operation, errors)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: AdvancedOperation, withErrors errors: [Error]) {
    self.willCancelOperationHandler?(operationQueue, operation, errors)
  }

  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: AdvancedOperation, withErrors errors: [Error]) {
    self.didCancelOperationHandler?(operationQueue, operation, errors)
  }

}

// MARK: - Composable Operations

/// An `AdvancedOperation` with input and output values.
internal class FunctionOperation<I, O> : AdvancedOperation, OperationInputHaving & OperationOutputHaving {
  /// A generic input.
  public var input: I?

  /// A generic output.
  public var output: O?
}

/// This operation output is nil if the input is greater than **1000**
/// This operation cancels itself if the input is **100**
internal class IntToStringOperation: AdvancedOperation & OperationInputHaving & OperationOutputHaving {
  var input: Int?
  var output: String?

  override init() {
    super.init()
  }

  override func main() {
    if let input = self.input {
      if input == 100 {
        output = "\(input)"
        cancel()
        finish()
      } else if input == 404 {
        output = nil
      } else if input <= 1000 {
        output = "\(input)"
      }
      finish()
    } else {
      finish(errors: [MockError.failed])
    }
  }
}

internal class StringToIntOperation: FunctionOperation<String, Int> {

  override init() {
    super.init()
  }

  override func main() {
    if let input = self.input, let value = Int(input) {
      output = value
      finish()
    } else {
      finish(errors: [MockError.failed])
    }
  }
}

// MARK: - Conditions

internal struct SlowCondition: OperationCondition {

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    DispatchQueue(label: "SlowCondition").asyncAfter(deadline: .now() + 10) {
      completion(.satisfied)
    }
  }

}

internal struct AlwaysFailingCondition: OperationCondition {

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    completion(.failed([MockError.failed]))
  }

}

internal struct AlwaysSuccessingCondition: OperationCondition {

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    completion(.satisfied)
  }

}
