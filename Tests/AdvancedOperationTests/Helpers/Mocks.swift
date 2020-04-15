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

import Foundation
import Dispatch
import XCTest
@testable import AdvancedOperation

// MARK: - AsynchronousBlockOperation

internal final class SleepyAsyncOperation: AsynchronousOperation {
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

// MARK: - AsynchronousOperation

internal final class NotExecutableOperation: AsynchronousOperation {
  override func main() {
    XCTFail("This operation shouldn't be executed.")
    self.finish()
  }
}

internal final class AutoCancellingAsyncOperation: AsynchronousOperation {
  override func main() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
      self.cancel()
      self.finish()
    }
  }
}

internal final class RunUntilCancelledAsyncOperation: AsynchronousOperation {
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
internal final class InfiniteAsyncOperation: AsyncOperation {
  var onExecutionStarted: (() -> Void)?
  let isStopped = Atomic(false)
  func stop() {
    isStopped.mutate { $0 = true }
  }

  override func main() {
    DispatchQueue(label: "InfiniteOperationQueue").async {
      self.onExecutionStarted?()
      while true {
        //sleep(1)
        if self.isStopped.value {
          self.finish()
          break
        }
      }
    }
  }
}

/// Operation expected to be cancelled before starting its execution.
internal final class CancelledOperation: Operation {
  private let file: StaticString
  private let line: UInt
  init(file: StaticString = #file, line: UInt = #line) {
    self.file = file
    self.line = line
    super.init()
  }

  override func main() {
    XCTAssert(isCancelled, "This operation is expected to be cancelled before starting its execution.", file: file, line: line)
  }
}

// MARK: - Operation

internal final class IntToStringOperation: Operation {
  var onOutputProduced: ((String) -> Void)?
  var input: Int?
  private(set) var output: String? {
    get {
      return _output.value
    }
    set {
      _output.mutate { $0 = newValue }
    }
  }

  // To fix data race error on macOS tests: see testSuccessfulInjectionBetweenOperationsTransformingOutput
  private var _output = Atomic<String?>(nil)

  override func main() {
    if let input = self.input {
      output = "\(input)"
      onOutputProduced?(self.output!)
    }
  }
}

internal final class StringToIntOperation: Operation  {
  var onOutputProduced: ((Int) -> Void)?
  var input: String?
  private(set) var output: Int? {
    get {
      return _output.value
    }
    set {
      _output.mutate { $0 = newValue }
    }
  }

  // To fix data race error on macOS tests: see testSuccessfulInjectionBetweenOperationsTransformingOutput
  private var _output = Atomic<Int?>(nil)

  override func main() {
    if let input = self.input {
      output = Int(input)
      self.onOutputProduced?(output!)
    }
  }
}

// MARK: - AsynchronousOperation

internal final class FailingOperation: Operation {
  enum FailureError: Error {
    case errorOne
    case errorTwo
  }

  private(set) var error: FailureError?

  override func main() {
    self.error = .errorOne
  }
}

// MARK: - GroupOperation

internal final class ProducerGroupOperation: GroupOperation {
  init(operation: @escaping () -> Operation) {
    super.init(operations: [])
    let producer = BlockOperation { [unowned self] in
      // operation can be "produced" and added to the GroupOperation only if the producer is still running
      self.addOperation(operation())
    }
    self.addOperation(producer)
  }
}

internal final class IOGroupOperation: GroupOperation {
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
