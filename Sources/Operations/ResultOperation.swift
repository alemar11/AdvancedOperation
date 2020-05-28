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

public protocol OperationError: Error {
  /// An error indicating that the operation has been cancelled.
  static var cancelled: Self { get }
}

/// An `AsynchronousOperation` that produces a `result` once finished.
///
/// If a `ResultOperation` gets cancelled before being executed, it will finish with a `OperationError.cancelled` failure result as soon as it gets started.
open class ResultOperation<Success, Failure>: AsynchronousOperation where Failure: OperationError {
  public var onResultProduced: ((Result<Success, Failure>) -> Void)?
  private var _result = Atomic<Result<Success, Failure>?>(nil)

  public final private(set) var result: Result<Success, Failure>? {
    get { return _result.value }
    set { _result.mutate { $0 = newValue } }
  }

  /// Finishes the operation with the produced `result`.
  /// - Important: You should never call this method outside the operation main execution scope.
  public final func finish(with result: Result<Success, Failure>) {
    self.result = result
    onResultProduced?(result)
    super.finish()
  }

  public final override func finish() {
    // If an operation starts but it's already cancelled, if won't be executed;
    // instead finish() will be called.
    // In that case the ResultOperation will finish with a failure result.
    if !isExecuting && isCancelled {
      finish(with: .failure(.cancelled))
    } else {
      fatalError("Use finish(with:) instead.")
    }
  }
}

public typealias FailableAsyncOperation = FailableAsynchronousOperation

/// An `AsynchronousOperation` that can finish with an error conforming to `OperationError`.
///
/// If a `FailableAsynchronousOperation` gets cancelled before being executed, it will finish with a `OperationError.cancelled` error as soon as it gets started.
open class FailableAsynchronousOperation<Failure: OperationError>: AsynchronousOperation {
  public private(set) var error: Failure?

  /// Finishes the operation with an `error`.
  /// - Important: You should never call this method outside the operation main execution scope.
  public func finish(with error: Failure) {
    self.error = error
    super.finish()
  }

  public final override func finish() {
    if isCancelled && !isExecuting {
      finish(with: .cancelled)
    } else {
      super.finish()
    }
  }
}
