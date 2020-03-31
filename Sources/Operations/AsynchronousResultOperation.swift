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

public typealias AsyncResultOperation = AsynchronousResultOperation

/// Errors conforming to this protocol have some pre-defined cases.
///
/// - Warning: To support this protocol prior Swift 5.3 use the workaround described here: https://github.com/apple/swift-evolution/blob/master/proposals/0280-enum-cases-as-protocol-witnesses.md
public protocol OperationError: Error {
  static var notExecuted: Self { get }
  static var cancelled: Self { get }
}

/// An `AsynchronousOperation` subclass which produces a `Result` type output.
///
/// If the operation gets cancelled, its result will be set immediatly to `.cancelled` error and the `onResultProduced` will be called.
open class AsynchronousResultOperation<Success, Failure>: AsynchronousOperation where Failure: OperationError {
  public var onResultProduced: ((Result<Success, Failure>) -> Void)?

  public final private(set) var result: Result<Success, Failure>! {
    get {
      return _result.value
    }
    set {
      _result.mutate { [weak self] output -> Void in
        output = newValue
        self?.onResultProduced?(newValue)
      }
    }
  }

  /// Underlying synchronized result to avoid data races when setting the result from both cancel() or finish(with:) at the same time.
  private var _result = Atomic<Result<Success, Failure>>(.failure(.notExecuted))
  private let cancelLock = UnfairLock()

  open override func cancel() {
    cancelLock.lock()
    defer { cancelLock.unlock() }

    if !isCancelled {
      self.result = .failure(.cancelled)
    }
    super.cancel()
  }

  /// Finishes the operation with a `result`.
  /// - Important: You should never call this method outside the operation main execution scope.
  public final func finish(with result: Result<Success, Failure>) {
    // An assert is enough since finish(result:) is the only public method to set the output.
    // the operation will crash if finish(result:) method is called more than once (see finish() implementation).
    assert(isExecuting, "result can only be set if \(operationName) is executing.")
    precondition(!isCancelled, "\(operationName) is cancelled therefore the result contains already a .cancelled error, use finish() instead.")
    self.result = result

    finish()
  }
}
