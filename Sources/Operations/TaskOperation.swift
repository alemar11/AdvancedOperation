// TaskOperation

import Foundation

#if compiler(>=5.5.2) && canImport(_Concurrency)

/// An `AsynchronousOperation` that supports Swift concurrency.
@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public final class TaskOperation: AsynchronousOperation {
  public typealias Block = @Sendable () async -> Void
  
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

/// An `AsynchronousOperation` that supports Swift concurrency.
@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public final class FailableTaskOperation: FailableAsynchronousOperation<Error> {
  public typealias Block = @Sendable () async throws -> Void
  
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
      guard !Task.isCancelled else {
        finish()
        return
      }
      do {
        try await block()
        finish()
      }  catch {
        finish(with: error)
      }
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

/// An `AsynchronousOperation` that supports Swift concurrency.
@available(iOS 13.0, iOSApplicationExtension 13.0, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public final class ResultTaskOperation<Success, Failure>: ResultOperation<Success, Error> {
  public typealias Block = @Sendable () async throws -> Success

  // MARK: - Private Properties

  private var block: Block
  private var task: (Task<Void, Never>)?

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
      do {
        try Task.checkCancellation()
        let result = try await block()
        finish(with: .success(result))
      } catch {
        finish(with: .failure(error))
      }
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
#endif
