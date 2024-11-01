// AdvancedOperation

import Foundation
import os.lock

/// An `AsynchronousOperation` that produces a `result` once finished.
///
/// If a `ResultOperation` gets cancelled before being executed, no result will be produced by default.
open class ResultOperation<Success, Failure>: AsynchronousOperation, @unchecked Sendable where Success: Sendable, Failure: Error {
  /// Block executed after the operation is finished providing the final result (if any).
  /// - Note: `onFinish` and `completionBlock` call order is not guaranteed in any way.
  public var onFinish: ((Result<Success, Failure>?) -> Void)?

  /// The result produced by the operation.
  public final private(set) var result: Result<Success, Failure>? {
    get { _result.withLock { $0 } }
    set { _result.withLock { $0 = newValue } }
  }

  private var _result = OSAllocatedUnfairLock<Result<Success, Failure>?>(initialState: nil)

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
