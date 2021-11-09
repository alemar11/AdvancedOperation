// TaskOperation

import Foundation

/// An `AsynchronousOperation` that supports Swift concurrency.
@available(swift 5.5)
@available(iOS 15.0, iOSApplicationExtension 15.0, macCatalyst 15.0, tvOS 15.0, watchOS 8.0, macOS 12, *)
public final class TaskOperation: AsynchronousOperation {
  public typealias Block =  @Sendable () async -> Void

  // MARK: - Private Properties

  private var block: Block
  private var task: (Task<(), Never>)?

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes.
  public init(block: @escaping Block) {
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

    let priority = priority()
    task = Task(priority: priority) {
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

  private func priority() -> TaskPriority {
    switch qualityOfService {
      case .background:
        return TaskPriority.background
      case .default:
        return TaskPriority.medium
      case .userInitiated:
        return TaskPriority.userInitiated
      case .userInteractive:
        return TaskPriority.high
      case .utility:
        return TaskPriority.utility
      @unknown default:
        return TaskPriority.medium
    }
  }
}
