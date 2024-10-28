// AdvancedOperation

import Foundation
import os.lock

public typealias AsyncBlockOperation = AsynchronousBlockOperation

/// A  sublcass of `AsynchronousOperation` to execute a closure.
///  - Note: If the operation gets cancelled before being executed, the block won't be called.
 ///
 /// This operation let you run a block until *complete* is called.
 ///   ```
 ///   let operation = AsyncCancellableBlockOperation { complete in
 ///    // work ...
 ///    complete()
 ///   }
public final class AsynchronousBlockOperation: AsynchronousOperation, @unchecked Sendable {
  // MARK: - Private Properties

  private let block: (@Sendable @escaping () -> Void) -> Void

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes; the parameter passed to the block **MUST** be invoked by your code,
  ///   or else the `AsynchronousBlockOperation` will never finish executing.
  public init(block: @Sendable @escaping (@Sendable @escaping () -> Void) -> Void) {
    // block is @Sendable because of https://github.com/swiftlang/swift/issues/75453#issuecomment-2374682664
    self.block = block
    super.init()
    self.name = "\(type(of: self))"
  }

  // MARK: - Overrides

  public final override func main() {
    guard !isCancelled else {
      self.finish()
      return
    }

    block {
      self.finish()
    }
  }
}
