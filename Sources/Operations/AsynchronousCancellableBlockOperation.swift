// AdvancedOperation

public typealias AsyncCancellableBlockOperation = AsynchronousCancellableBlockOperation

/// A  sublcass of `AsynchronousOperation` to execute a cancellable closure.
///  - Note: If the operation gets cancelled before being executed, the block won't be called.
///
/// This operation let you run a block until *complete* is called; its cancelled state is exposed during the whole execution.
///   ```
///   let operation = AsyncCancellableBlockOperation { isCancelled, complete in
///    // work ...
///    if isCancelled() {
///      complete()
///      return
///    }
///    // work ...
///    complete()
///   }
public final class AsynchronousCancellableBlockOperation: AsynchronousOperation {
  /// A closure type that takes a closure as its parameter.
  public typealias Block = (@escaping @Sendable () -> Bool, @escaping @Sendable () -> Void) -> Void
  
  // MARK: - Private Properties

  private var block: Block

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes; the parameter passed to the block **MUST** be invoked by your code,
  ///   or else the `AsynchronousBlockOperation` will never finish executing.
  public init(block: @escaping Block) {
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
    
    block ({
      self.isCancelled
    }) {
      self.finish()
    }
  }
}
