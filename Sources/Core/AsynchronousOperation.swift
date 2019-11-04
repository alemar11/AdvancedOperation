//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
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

// https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW8
// https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html
// Source/Inspiration: https://stackoverflow.com/a/48104095/116862 and https://gist.github.com/calebd/93fa347397cec5f88233

import Foundation
import os.log

/// An abstract thread safe subclass of `Operation` to build asynchronous operations.
/// Subclasses must override `execute(completion:)` to perform any work and call the completion handler to finish it.
open class AsynchronousOperation<T>: Operation, OutputProducing {
  public typealias Output = Result<T,Error>

  // MARK: - Public Properties

  open override var isReady: Bool {
    return state == .ready && super.isReady
  }

  public final override var isExecuting: Bool {
    return state == .executing
  }

  public final override var isFinished: Bool {
    return state == .finished
  }

  public final override var isAsynchronous: Bool { return true }

  /// The output produced by the `AsynchronousOperation`.
  public private(set) var output: Output = .failure(NSError.AdvancedOperation.noOutputYet)

  /// The `OSLog` instance used to track the main operation changes (by default is disabled).
  public var log: OSLog {
    get {
      return _log.value
    }
    set {
      precondition(state == .ready, "Cannot add OSLog if the operation is \(state).")
      _log.mutate { $0 = newValue }
    }
  }

  // MARK: - Private Properties

  /// Lock to ensure thread safety.
  private let lock = UnfairLock()

  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).AsynchronousOperation.stateChange")

  /// The state of the operation
  private var state: State {
    get {
      return _state.value
    }
    set {
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
        let oldValue = _state.value
        //guard newValue != oldValue else { return }

        willChangeValue(forKey: oldValue.objcKeyPath)
        willChangeValue(forKey: newValue.objcKeyPath)

        _state.mutate {
          assert($0.canTransition(to: newValue), "Performing an invalid state transition from: \($0) to: \(newValue).")
          $0 = newValue
        }

        didChangeValue(forKey: oldValue.objcKeyPath)
        didChangeValue(forKey: newValue.objcKeyPath)
      }
    }
  }

  /// Private backing store for `state`
  private var _state: Atomic<State> = Atomic(.ready)

  private var _log = Atomic(OSLog.disabled)

  // MARK: - Foundation.Operation

  public final override func start() {
    if isCancelled {
      // early bailing out
      finish(result: .failure(NSError.AdvancedOperation.cancelled))
      return
    }

    /// The default implementation of this method updates the execution state of the operation and calls the receiver’s main() method.
    /// This method also performs several checks to ensure that the operation can actually run.
    /// For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    /// If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    super.start()

    // At this point main() has already returned but it doesn't mean that the operation is finished.
    // Only the execute(completion:) overidden implementation can finish the operation now.
  }

  // MARK: - Public

  /// Subclasses must implement this to perform their work and they must not call `super`.
  /// The default implementation of this function traps.
  public final override func main() {
    state = .executing
    os_log("%{public}s has started.", log: log, type: .info, operationName)
    execute(completion: finish)
  }

  open func execute(completion: @escaping (Output) -> Void) {
    preconditionFailure("Subclasses must implement `execute`.")
  }

  /// A subclass will probably need to override `cleanup` to tear down resources.
  ///
  /// At this point the operation is about to be finished and the final output is already created.
  /// - Note: It is called even if the operation is cancelled.
  open func cleanup() {
    // subclass
  }

  open override func cancel() {
    lock.lock()
    defer { lock.unlock() }

    guard !isCancelled else { return }

    super.cancel()
    os_log("%{public}s has been cancelled.", log: log, type: .info, operationName)
  }

  /// Call this function to finish an operation that is currently executing.
  private final func finish(result: Output) {
    // State can also be "ready" here if the operation was cancelled before it started.
    lock.lock()
    defer { lock.unlock() }

    switch state {
    case .ready, .executing:
      self.output = result
      cleanup()
      state = .finished
      if log != .disabled {
        switch output {
        case .success:
          os_log("%{public}s has finished.", log: log, type: .info, operationName)
        case .failure(let error):
          os_log("%{public}s has finished with error: %{private}s.", log: log, type: .error, operationName, error.localizedDescription)
        }
      }
    case .finished:
      return
    }
  }

  open override var description: String {
    return debugDescription
  }

  open override var debugDescription: String {
    return "\(operationName)) – \(isCancelled ? "cancelled" : String(describing: state))"
  }
}

// MARK: - State

extension AsynchronousOperation {
  /// Mirror of the possible states an Operation can be in.
  enum State: Int, CustomStringConvertible, CustomDebugStringConvertible {
    case ready
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
      return description
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
