// AdvancedOperation

import Foundation
import os.lock

public typealias FailableAsyncOperation = FailableAsynchronousOperation

/// An `AsynchronousOperation` that can finish with an error conforming to `OperationError`.
open class FailableAsynchronousOperation<Failure: Error>: AsynchronousOperation {
  private var _error = OSAllocatedUnfairLock<Failure?>(initialState: nil)

  /// Failure error.
  public final private(set) var error: Failure? {
    get { _error.withLock { $0 } }
    set { _error.withLock { $0 = newValue } }
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
