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

public typealias FailableAsyncOperation = FailableAsynchronousOperation

/// An `AsynchronousOperation` that can finish with an error conforming to `OperationError`.
open class FailableAsynchronousOperation<Failure: Error>: AsynchronousOperation {
  private var _error = Atomic<Failure?>(nil)

  /// Failure error.
  public final private(set) var error: Failure? {
    get { return _error.value }
    set { _error.mutate { $0 = newValue } }
  }

  /// Finishes the operation with an `error`.
  /// - Important: You should never call this method outside the operation main execution scope.
  public func finish(with error: Failure) {
    self.error = error
    super.finish()
  }

  /// Cancels the operation with an `error`.
  open func cancel(with error: Failure) {
    self.error = error
    super.cancel()
  }
}
