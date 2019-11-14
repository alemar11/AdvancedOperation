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
//
// https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW8
// https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html

import Foundation
import os.log

/// An abstract thread safe subclass of `Operation` to build asynchronous operations.
///
/// Subclasses must override `execute(completion:)` to perform any work and call the completion handler to finish it.
///
/// To enable logging:
/// - To enable log add this environment key: `org.tinrobots.AdvancedOperation.LOG_ENABLED`
/// - To enable signposts add this environment key: `org.tinrobots.AdvancedOperation.SIGNPOST_ENABLED`
open class AsynchronousOperation<T>: Operation, OutputProducing {
  public typealias OperationOutput = Result<T, Error>

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

  public final override var isConcurrent: Bool { return true }

  /// The output produced by the `AsynchronousOperation`.
  /// It's `nil` while the operation is not finished.
  public private(set) var output: OperationOutput?

  // MARK: - Private Properties

  // An identifier you use to distinguish signposts that have the same name and that log to the same OSLog.
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  private lazy var signpostID = {
    return OSSignpostID(log: Log.signpost, object: self)
  }()

  // MARK: - Private Properties

  /// Lock to ensure thread safety.
  private let lock = UnfairLock()

  /// An operation is considered as "running" since the `start()` method is called until it gets finished.
  private var isRunning = Atomic(false)

  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).AsynchronousOperation.stateChange")

  /// The state of the operation
  private var state: State {
    get {
      return _state.value
    }
    set {
      // credits: https://gist.github.com/ole/5034ce19c62d248018581b1db0eabb2b
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
        guard newValue != oldValue else { return }

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

  // MARK: - Foundation.Operation

  public final override func start() {
    guard !isFinished else { return }

    // The super.start() method is already able to disambiguate started operations (see notes below)
    // but we need this to support os_log and os_signpost without having duplicates.
    let isAlreadyRunning = isRunning.mutate { running -> Bool in
      if running {
        return true
      } else {
        // it will be considered as running from now on
        running = true
        return false
      }
    }

    guard !isAlreadyRunning else { return }

    // early bailing out
    if isCancelled {
      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        os_log(.info, log: Log.general, "%{public}s has started after being cancelled.", operationName)
        os_signpost(.begin, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has started.", operationName)
      } else {
        os_log("%{public}s has started after being cancelled.", log: Log.general, type: .info, operationName)
      }

      finish(result: .failure(NSError.AdvancedOperation.cancelled))
      return
    }

    if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
      os_log(.info, log: Log.general, "%{public}s has started.", operationName)
      os_signpost(.begin, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has started.", operationName)
    } else {
      os_log("%{public}s has started.", log: Log.general, type: .info, operationName)
    }

    /// The default implementation of this method updates the execution state of the operation and calls the receiver’s main() method.
    /// This method also performs several checks to ensure that the operation can actually run.
    /// For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    /// If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    super.start()

    // At this point main() has already returned but it doesn't mean that the operation is finished.
    // Only the execute(completion:) overidden implementation can finish the operation now.
  }

  // MARK: - Public Methods

  public final override func main() {
    state = .executing

    if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
      os_signpost(.event, log: Log.poi, name: "Execution", signpostID: signpostID, "%{public}s is executing.", operationName)
    }

    if isCancelled {
      finish(result: .failure(NSError.AdvancedOperation.cancelled))
    } else {
      execute(completion: finish)
    }
  }

  /// Subclasses must implement this to perform their work and they must not call `super`.
  /// The default implementation of this function traps.
  /// - Note: Before calling this method, the operation checks if it's already cancelled (and, in that case, finishes itself).
  open func execute(completion: @escaping (OperationOutput) -> Void) {
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

    if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
      os_log(.info, log: Log.general, "%{public}s has been cancelled.", operationName)
    } else {
      os_log("%{public}s has been cancelled.", log: Log.general, type: .info, operationName)
    }

    if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
      os_signpost(.event, log: Log.poi, name: "Cancellation", signpostID: signpostID, "%{public}s has been cancelled.", operationName)
    }
  }

  // MARK: - Private Methods

  /// Call this function to finish an operation that is currently executing.
  private final func finish(result: OperationOutput) {
    // State can also be "ready" here if the operation was cancelled before it was started.
    guard !isFinished else { return }

    lock.lock()
    defer { lock.unlock() }

    switch state {
    case .ready, .executing:
      self.output = result
      cleanup()
      state = .finished
      isRunning.mutate { $0 = false }

      switch output! {
      case .success:
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_log(.info, log: Log.general, "%{public}s has finished.", operationName)
          os_signpost(.end, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has finished.", operationName)
        } else {
          os_log("%{public}s has finished.", log: Log.general, type: .info, operationName)
        }

      case .failure(let error):
        let debugErrorMessage = (error as NSError).debugErrorMessage

        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_log(.info, log: Log.general, "%{public}s has finished with error: '%{private}s'.", operationName, debugErrorMessage)
          os_signpost(.end, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has finished with error: '%{private}s'.", operationName, debugErrorMessage)
        } else {
          os_log("%{public}s has finished with error: '%{private}s'.", log: Log.general, type: .error, operationName, debugErrorMessage)
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

// MARK: - Log

private enum Log {
  /// The name used for signpost interval events (.begin and .end).
  static let signPostIntervalName: StaticString = "Operation"

  /// The `OSLog` instance used to track the operation changes (by default is disabled).
  static var general: OSLog {
    if ProcessInfo.processInfo.environment.keys.contains("\(identifier).LOG_ENABLED") {
      return OSLog(subsystem: identifier, category: "Operation")
    } else {
      return .disabled
    }
  }

  /// The `OSLog` instance used to track operation signposts (by default is disabled).
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  static var signpost: OSLog {
    if ProcessInfo.processInfo.environment.keys.contains("\(identifier).SIGNPOST_ENABLED") {
      return OSLog(subsystem: identifier, category: .pointsOfInterest)
    } else {
      return .disabled
    }
  }

  /// The `OSLog` instance used to track operation point of interests (by default is disabled).
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  static var poi: OSLog {
    if ProcessInfo.processInfo.environment.keys.contains("\(identifier).SIGNPOST_ENABLED") {
      return OSLog(subsystem: identifier, category: .pointsOfInterest)
    } else {
      return .disabled
    }
  }
}
