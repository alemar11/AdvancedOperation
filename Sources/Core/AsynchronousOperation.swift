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
// Source/Inspiration: https://stackoverflow.com/a/48104095/116862 and https://gist.github.com/calebd/93fa347397cec5f88233

import Foundation
import os.log

/// An abstract subclass of `Operation` to build asynchronous operations.
/// Subclasses must override `execute(completion:)` to perform any work and call the completion handler to finish it.
open class AsynchronousOperation<T>: Operation, OutputProducing {
  public typealias Output = Result<T,Error>

  public final override var isAsynchronous: Bool { return true }
  public private(set) var output: Output = .failure(NSError.notStarted)

  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).AsynchronousOperation.stateChange")

  /// Private backing store for `state`
  private var _state: Atomic<State> = Atomic(.ready)

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

  private var _log = Atomic(OSLog.disabled) // TODO: work in progress

  /// An instance of `OSLog` (by default is disabled).
  public var log: OSLog {
    get {
      return _log.value
    }
    set {
      precondition(state == .ready, "Cannot add OSLog if the operation is \(state).")
      _log.mutate { $0 = newValue }
    }
  }

  private var _conditions = Atomic([Condition]())

  /// Conditions evaluated before executing the operation task.
  public var conditions: [Condition] {
    return _conditions.value
  }

  open override var isReady: Bool {
    return state == .ready && super.isReady
  }

  public final override var isExecuting: Bool {
    return state == .executing
  }

  public final override var isFinished: Bool {
    return state == .finished
  }

  // MARK: - Foundation.Operation

  public final override func start() {
    if isCancelled {
      // early bailing out
      let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil) // TODO
      finish(result: .failure(error))
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

    // 1. evaluate conditions
    if let error = evaluateConditions() {
      self.cancel()
      finish(result: .failure(error))
      return
    }

    // 2. execute the real task
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

  private let lock = UnfairLock()

  /// Call this function to finish an operation that is currently executing.
  /// State can also be "ready" here if the operation was cancelled before it started.
  private final func finish(result: Output) {
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

  final public func addCondition(_ condition: Condition) {
    _conditions.mutate { $0.append(condition) }
  }

  open override var description: String {
    return debugDescription
  }

  open override var debugDescription: String {
    // TODO more details here being a debug description
    return "\(operationName)) – \(isCancelled ? "cancelled" : String(describing: state))"
  }
}

// MARK: - Conditions

extension AsynchronousOperation {
  private func evaluateConditions() -> Error? {
    guard !conditions.isEmpty else { return nil }

    return Self.evaluateConditions(conditions, for: self)
  }

  private static func evaluateConditions(_ conditions: [Condition], for operation: Operation) -> Error? {
    let conditionGroup = DispatchGroup()
    var results = [Result<Void, Error>?](repeating: nil, count: conditions.count)
    let lock = UnfairLock()

    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        lock.synchronized {
          results[index] = result
        }
        conditionGroup.leave()
      }
    }

    conditionGroup.wait()

    let errors = results.compactMap { $0?.failure }
    if errors.isEmpty {
      return nil
    } else {
      let aggregateError = NSError.conditionsEvaluationFinished(message: "\(operation.operationName) didn't pass the conditions evaluation.", errors: errors)
      return aggregateError
    }
  }
}

// MARK: - State

extension AsynchronousOperation {
  /// Mirror of the possible states an Operation can be in.
  internal enum State: Int, CustomStringConvertible, CustomDebugStringConvertible {
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
      case (.ready, .finished): return true // investigate (start after a cancel)
      case (.executing, .finished): return true
      default: return false
      }
    }
  }
}

extension NSError {
  static let notStarted = NSError(domain: identifier, code: 1, userInfo: nil)
  static let cancelled = NSError(domain: identifier, code: 2, userInfo: nil)
}

