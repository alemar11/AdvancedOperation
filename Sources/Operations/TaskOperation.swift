// TaskOperation

import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)

/// An `AsynchronousOperation` that supports Swift concurrency.
@available(swift 5.5)
@available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *)
public final class TaskOperation: AsynchronousOperation {
  public typealias Block =  @Sendable () async -> Void

  /// Priority to determine how e when the task gets scheduled.
  public let priority: _Concurrency.TaskPriority

  // MARK: - Private Properties

  private var block: Block
  private var task: (Task<(), Never>)?

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes.
  public init(priority: _Concurrency.TaskPriority = .medium, block: @escaping Block) {
    self.priority = priority
    self.block = block
    super.init()
    self.name = "\(type(of: self))"
  }

  // MARK: - Overrides

  public final override func main() {
    guard !isCancelled else {
      finish()
      return
    }

    task = Task(priority: priority) {
      // without setting a priority, it seems it gets High (25)
      if !Task.isCancelled {
        await block()
      }
      finish()
    }
  }

  public override func cancel() {
    task?.cancel()
    super.cancel()
  }
}

#endif
