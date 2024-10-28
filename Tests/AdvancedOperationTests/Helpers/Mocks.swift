// AdvancedOperation

import Dispatch
import Foundation
import XCTest
import os.lock

@testable import AdvancedOperation

// MARK: - AsynchronousBlockOperation

internal final class SleepyAsyncOperation: AsynchronousOperation, @unchecked Sendable {
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
    DispatchQueue.global().async {
      if self.isCancelled {
        self.finish()
        return
      }

      sleep(self.interval1)

      if self.isCancelled {
        self.finish()
        return
      }

      sleep(self.interval2)

      if self.isCancelled {
        self.finish()
        return
      }

      sleep(self.interval3)
      self.finish()
    }
  }
}

final class ProgressReportingAsyncOperation: AsyncOperation, @unchecked Sendable {
  override func main() {
    DispatchQueue.global().async {
      if self.isCancelled {
        self.finish()
        return
      }
      self.progress.totalUnitCount = 4
      usleep(1_000_000)  // 1 sec
      self.progress.completedUnitCount = 1
      usleep(500_000)  // 0,5 sec
      self.progress.completedUnitCount = 2
      usleep(100_000)  // 0,1 sec
      self.progress.completedUnitCount = 3
      usleep(1000)  // 0,001 sec
      self.finish()
    }
  }
}

// MARK: - AsynchronousOperation

internal final class NotExecutableOperation: AsynchronousOperation, @unchecked Sendable {
  override func main() {
    XCTFail("This operation shouldn't be executed.")
    self.finish()
  }
}

internal final class AutoCancellingAsyncOperation: AsynchronousOperation, @unchecked Sendable {
  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
      self.cancel()
      self.finish()
    }
  }
}

internal final class RunUntilCancelledAsyncOperation: AsynchronousOperation, @unchecked Sendable {
  let queue: DispatchQueue

  init(queue: DispatchQueue = DispatchQueue.global()) {
    self.queue = queue
  }

  override func main() {
    queue.async {
      while !self.isCancelled {
        //sleep(1)
      }
      self.finish()
    }
  }
}

/// This operation will run indefinitely and can't be cancelled. Call `stop` to finish it.
internal final class InfiniteAsyncOperation: AsyncOperation, @unchecked Sendable {
  var onExecutionStarted: (() -> Void)?
  let isStopped = OSAllocatedUnfairLock(initialState: false)
  func stop() {
    isStopped.withLock { $0 = true }
  }

  override func main() {
    DispatchQueue(label: "InfiniteOperationQueue").async {
      self.onExecutionStarted?()
      while true {
        //sleep(1)
        if self.isStopped.withLock({ $0 }) {
          self.finish()
          break
        }
      }
    }
  }
}

/// Operation expected to be cancelled before starting its execution.
internal final class CancelledOperation: Operation, @unchecked Sendable {
  private let file: StaticString
  private let line: UInt
  init(file: StaticString = #file, line: UInt = #line) {
    self.file = file
    self.line = line
    super.init()
  }

  override func main() {
    XCTAssert(
      isCancelled, "This operation is expected to be cancelled before starting its execution.", file: file, line: line)
  }
}

// MARK: - Operation

internal final class IntToStringOperation: Operation, @unchecked Sendable {
  var onOutputProduced: ((String) -> Void)?
  var input: Int?
  private(set) var output: String? {
    get { _output.withLock { $0 } }
    set { _output.withLock { $0 = newValue } }
  }

  // To fix data race error on macOS tests: see testSuccessfulInjectionBetweenOperationsTransformingOutput
  private var _output = OSAllocatedUnfairLock<String?>(initialState: nil)

  override func main() {
    if let input = self.input {
      output = "\(input)"
      onOutputProduced?(self.output!)
    }
  }
}

internal final class StringToIntOperation: Operation, @unchecked Sendable {
  var onOutputProduced: ((Int) -> Void)?
  var input: String?
  private(set) var output: Int? {
    get { _output.withLock { $0 } }
    set { _output.withLock { $0 = newValue } }
  }

  // To fix data race error on macOS tests: see testSuccessfulInjectionBetweenOperationsTransformingOutput
  private var _output = OSAllocatedUnfairLock<Int?>(initialState: nil)

  override func main() {
    if let input = self.input {
      output = Int(input)
      self.onOutputProduced?(output!)
    }
  }
}

// MARK: - AsynchronousOperation

internal final class FailingOperation: Operation, @unchecked Sendable {
  enum FailureError: Error {
    case errorOne
    case errorTwo
  }

  private(set) var error: FailureError?

  override func main() {
    self.error = .errorOne
  }
}

// MARK: - ResultOperation

internal final class DummyResultOperation: ResultOperation<String, DummyResultOperation.Error>, @unchecked Sendable {
  enum Error: Swift.Error {
    case cancelled
  }

  let setFailureOnEarlyBailOut: Bool

  init(setFailureOnEarlyBailOut: Bool = true) {
    self.setFailureOnEarlyBailOut = setFailureOnEarlyBailOut
  }

  override func main() {
    if isCancelled {
      finish(with: .failure(.cancelled))
      return
    }
    DispatchQueue.global().async {
      self.finish(with: .success("Success"))
    }
  }

  override func cancel() {
    if setFailureOnEarlyBailOut {
      // makes sure that, even if the operation is cancelled before getting executed, there is a result when it finishes
      cancel(with: .cancelled)
    } else {
      super.cancel()
    }
  }
}

// MARK: - FailableAsyncOperation

internal final class DummyFailableOperation: FailableAsyncOperation<DummyFailableOperation.Error>, @unchecked Sendable {
  enum Error: Swift.Error {
    case cancelled
    case failed
    case other
  }

  let shouldFail: Bool

  init(shouldFail: Bool) {
    self.shouldFail = shouldFail
  }

  override func main() {
    if isCancelled {
      finish(with: .cancelled)
      return
    }
    DispatchQueue.global().async {
      if self.shouldFail {
        self.finish(with: .failed)
      } else {
        self.finish()
      }
    }
  }

  override func cancel() {
    // makes sure that, even if the operation is cancelled before getting executed,
    // there always be a result when it finishes
    cancel(with: .cancelled)
  }
}

// MARK: - GroupOperation

internal final class ProducerGroupOperation: GroupOperation, @unchecked Sendable {
  init(operation: @Sendable @escaping () -> Operation) {
    super.init(operations: [])
    let producer = BlockOperation { [unowned self] in
      // operation can be "produced" and added to the GroupOperation only if the producer is still running
      self.addOperation(operation())
    }
    self.addOperation(producer)
  }
}

internal final class IOGroupOperation: GroupOperation, @unchecked Sendable {
  var input: Int?
  private(set) var output: Int?
  var onOutputProduced: ((Int) -> Void)?

  init(input: Int? = nil) {
    super.init(operations: [])

    let inputOperation = IntToStringOperation()
    if let input = input {
      inputOperation.input = input
    } else {
      let op = BlockOperation { [unowned self, unowned inputOperation] in
        inputOperation.input = self.input
      }
      inputOperation.addDependency(op)
      self.addOperation(op)
    }

    let outputOperation = StringToIntOperation()
    let inject = BlockOperation { [unowned inputOperation, unowned outputOperation] in
      outputOperation.input = inputOperation.output
    }

    inject.addDependency(inputOperation)
    outputOperation.addDependency(inject)

    let exitOperation = BlockOperation { [unowned self, unowned outputOperation] in
      self.output = outputOperation.output
      if let output = self.output {
        self.onOutputProduced?(output)
      }
    }
    exitOperation.addDependency(outputOperation)

    self.addOperation(inputOperation)
    self.addOperation(inject)
    self.addOperation(outputOperation)
    self.addOperation(exitOperation)
  }
}

extension Operation {
  public func printStateChanges() -> [NSKeyValueObservation] {
    let cancel = observe(\.isCancelled, options: [.old, .new]) { (operation, changes) in
      guard let oldValue = changes.oldValue, let newValue = changes.newValue else { return }
      guard oldValue != newValue else { return }
      guard newValue else { return }
      print("\(operation.operationName) is cancelled.")
    }

    let executing = observe(\.isExecuting, options: [.old, .new]) { (operation, changes) in
      guard let oldValue = changes.oldValue, let newValue = changes.newValue else { return }
      guard oldValue != newValue else { return }
      guard newValue else { return }
      print("\(operation.operationName) is executing.")
    }

    let finish = observe(\.isFinished, options: [.old, .new]) { (operation, changes) in
      guard let oldValue = changes.oldValue, let newValue = changes.newValue else { return }
      guard oldValue != newValue else { return }
      guard newValue else { return }
      print("\(operation.operationName) is finished.")
    }
    return [cancel, executing, finish]
  }
}
