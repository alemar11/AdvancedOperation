// AdvancedOperation

import Foundation
import os.lock

public typealias AsyncOperation = AsynchronousOperation

/// An abstract thread safe subclass of `Operation` to support asynchronous operations.
///
/// Subclasses must override `main` to perform any work and, if they are asynchronous, call the `finish()` method to complete the execution.
open class AsynchronousOperation: Operation, ProgressReporting {
  // MARK: - Public Properties

  /// The `progress` property represents a total progress of the operation during its execution.
  @objc
  public final lazy private(set) var progress: Progress = {
    let progress = Progress(totalUnitCount: 1)
    progress.isPausable = false
    progress.isCancellable = true
    progress.cancellationHandler = { [weak self] in
      if let self = self, !self.isCancelled {
        self.cancel()
      }
    }
    return progress
  }()

  open override var isReady: Bool { state == .ready && super.isReady }

  public final override var isExecuting: Bool { state == .executing }

  public final override var isFinished: Bool { state == .finished }

  public final override var isAsynchronous: Bool { isConcurrent }

  public final override var isConcurrent: Bool { true }

  // MARK: - Private Properties

  /// Lock used to prevent data races when updating the progress.
  private let progressLock = OSAllocatedUnfairLock()

  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).AsynchronousOperation.stateChange")

  /// Private backing store for `state`
  private var _state = OSAllocatedUnfairLock<State>(initialState: .ready)

  /// The state of the operation
  private var state: State {
    get {
      _state.withLock { $0 }
    }
    set {
      // credits: https://gist.github.com/ole/5034ce19c62d248018581b1db0eabb2b
      // credits: https://github.com/radianttap/Swift-Essentials/issues/4
      // A state mutation should be a single atomic transaction. We can't simply perform
      // everything on the isolation queue for `_state` because the KVO willChange/didChange
      // notifications have to be sent from outside the isolation queue.
      // Otherwise we would deadlock because KVO observers will in turn try to read `state` (by calling
      // `isReady`, `isExecuting`, `isFinished`. Use a second queue to wrap the entire
      // transaction.
      stateChangeQueue.sync {
        // Retrieve the existing value first.
        // Necessary for sending fine-grained KVO
        // willChange/didChange notifications only for the key paths that actually change.
        let oldValue = _state.withLock { $0 }
        guard newValue != oldValue else { return }

        willChangeValue(forKey: newValue.objcKeyPath)
        willChangeValue(forKey: oldValue.objcKeyPath)

        _state.withLock {
          assert(
            $0.canTransition(to: newValue),
            "Performing an invalid state transition from: \($0) to: \(newValue) for \(operationName).")
          $0 = newValue
        }

        didChangeValue(forKey: oldValue.objcKeyPath)
        didChangeValue(forKey: newValue.objcKeyPath)
      }
    }
  }

  // MARK: - Foundation.Operation

  // Lock used to prevent data races if start() gets called multiple times from different threads
  private let startLock = OSAllocatedUnfairLock()

  public final override func start() {
    startLock.lock()
    defer { startLock.unlock() }

    switch state {
    case .finished:
      return
    case .executing:
      fatalError("The operation \(operationName) is already executing.")
    case .ready:
      // the internal state is ready but the isReady variable can be overidden by subclasses
      guard isReady else {
        fatalError("The operation \(operationName) is not yet ready to execute.")
      }

      // early bailing out
      guard !isCancelled else {
        finish()
        return
      }

      state = .executing

      // The OperationQueue progress reporting works correctly only if used with super.start()
      // but calling super.start() shouldn't be done when implementing custom concurrent operations.
      // To fix that we use a different progress instance
      if #available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
        progressLock.lock()
        if let currentQueue = OperationQueue.current, currentQueue.progress.totalUnitCount > 0 {
          currentQueue.progress.addChild(progress, withPendingUnitCount: 1)
        }
        progressLock.unlock()
      }

      main()

    // At this point `main()` has already returned but it doesn't mean that the operation is finished.
    // Only calling `finish()` will finish the operation.
    }
  }

  // MARK: - Public Methods

  /// The default implementation of this method does nothing.
  /// You should override this method to perform the desired task. In your implementation, do not invoke super.
  ///  This method will automatically execute within an autorelease pool provided by `Operation`, so you do not need to create your own autorelease pool block in your implementation.
  /// - Note: Once the task is finished you **must** call `finish()` to complete the execution.
  ///  - Warning: It won't be called if the operation gets cancelled before starting.
  open override func main() {
    preconditionFailure("Subclasses must implement `main()`.")
  }

  /// Finishes the operation.
  /// - Important: You should never call this method outside the operation main() execution scope.
  public func finish() {
    // State can also be "ready" here if the operation was cancelled before it was started.
    if !isFinished {
      progressLock.lock()
      if progress.completedUnitCount != progress.totalUnitCount {
        progress.completedUnitCount = progress.totalUnitCount
      }
      progressLock.unlock()

      // If multiple calls are made to finish() from different threads at the same time
      // setting the same state will trigger an assert in the state setter.
      // A lock isn't required.
      state = .finished
    } else {
      preconditionFailure("The finish() method shouldn't be called more than once for \(operationName).")
    }
  }

  open override func cancel() {
    super.cancel()

    progressLock.lock()
    if !progress.isCancelled {
      progress.cancel()
    }
    progressLock.unlock()
  }

  // MARK: - Debug

  open override var description: String { debugDescription }

  open override var debugDescription: String {
    "\(operationName) – \(isCancelled ? "cancelled (\(state))" : "\(state)")"
  }
}

// MARK: - AsynchronousOperation State

extension AsynchronousOperation {
  /// All the possible states an Operation can be in.
  enum State: Int, CustomStringConvertible, CustomDebugStringConvertible {
    case ready  // waiting to be executed
    case executing
    case finished

    /// The `#keyPath` for the `Operation` property that's associated with this value.
    var objcKeyPath: String {
      switch self {
      case .ready: return #keyPath(isReady)
      case .executing: return #keyPath(isExecuting)
      case .finished: return #keyPath(isFinished)
      }
    }

    var description: String {
      switch self {
      case .ready: return "ready"
      case .executing: return "executing"
      case .finished: return "finished"
      }
    }

    var debugDescription: String {
      description
    }

    func canTransition(to newState: State) -> Bool {
      switch (self, newState) {
      case (.ready, .executing): return true
      case (.ready, .finished): return true
      case (.executing, .finished): return true
      default: return false
      }
    }
  }
}
