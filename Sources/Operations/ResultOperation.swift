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

/// An `AsynchronousOperation` that produces a `result` once finished.
///
/// If a `ResultOperation` gets cancelled before being executed, no result will be produced by default.
open class ResultOperation<Success, Failure>: AsynchronousOperation where Failure: Error {
  /// Block executed after the operation is finished providing the final result (if any).
  /// - Note: `onFinish` and `completionBlock` call order is not guaranteed in any way.
  public var onFinish: ((Result<Success, Failure>?) -> Void)?

  /// The result produced by the operation.
  public final private(set) var result: Result<Success, Failure>? {
    get { _result.value }
    set { _result.mutate { $0 = newValue } }
  }

  private var _result = Atomic<Result<Success, Failure>?>(nil)

  /// Finishes the operation with the produced `result`.
  /// - Important: You should never call this method outside the operation main execution scope.
  public final func finish(with result: Result<Success, Failure>) {
    self.result = result
    _finish()
  }

  /// Cancels the operation with a `failure`.
  open func cancel(with failure: Failure) {
    self.result = .failure(failure)
    super.cancel()
  }

  public final override func finish() {
    if isExecuting {
      fatalError("Use finish(with:) instead.")
    }
    _finish()
  }

  private func _finish() {
    super.finish()
    onFinish?(result)
  }
}
