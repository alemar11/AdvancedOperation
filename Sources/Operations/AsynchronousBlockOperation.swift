// AdvancedOperation

import Foundation

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
  /// A closure type that takes a closure as its parameter.
  public typealias Block = (@Sendable @escaping () -> Void) -> Void

  // MARK: - Private Properties

  private var block: Block

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes; the parameter passed to the block **MUST** be invoked by your code,
  ///   or else the `AsynchronousBlockOperation` will never finish executing.
  public init(block:  @escaping Block) {
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
