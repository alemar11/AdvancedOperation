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

import Foundation
import os.log

public protocol InputConsuming: Operation {
  associatedtype Input
  var input: Input? { get set }
}

public protocol OutputProducing_NEW: Operation {
  associatedtype Output
  var output: Output { get }
}

/// An abstract class that makes building simple asynchronous operations easy.
/// Subclasses must override `main()` to perform any work and call `finish()`
/// when they are done. All `NSOperation` work will be handled automatically.
///
/// Source/Inspiration: https://stackoverflow.com/a/48104095/116862 and https://gist.github.com/calebd/93fa347397cec5f88233
open class AsynchronousOperation<T>: Operation, OutputProducing_NEW {
  public typealias Output = Result<T,Error>
  public private(set) var output: Output = .failure(NSError.notStarted)

  public init(name: String? = nil) {
    super.init()
    self.name = name
  }

  /// Serial queue for making state changes atomic under the constraint
  /// of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "com.alessandromarzoli.AsynchronousOperation.stateChange")

  /// Private backing store for `state`
  private var _state: Atomic<State> = Atomic(.ready)

  public final override var isAsynchronous: Bool { return true }

  /// An instance of `OSLog` (by default is disabled).
  public var log: OSLog {
    get {
      return _log.value
    }
    set {
      precondition(state == .ready, "Cannot add a OSLog if the operation is \(state).")
      _log.mutate { $0 = newValue }
    }
  }

  private var _log = Atomic(OSLog.disabled) // TODO: work in progress

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
    /// The default implementation of this method updates the execution state of the operation and calls the receiver’s main() method.
    /// This method also performs several checks to ensure that the operation can actually run.
    /// For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    /// If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    super.start()

    // At this point main() has already returned.
    if isCancelled {
      let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
      finish(result: .failure(error))
      return
    }
  }

  // MARK: - Public

  /// Subclasses must implement this to perform their work and they must not call `super`.
  /// The default implementation of this function traps.
  public final override func main() {
    guard !isCancelled else { return }

    state = .executing

    // TODO: before executing the operation we could validate it with some conditions
    // if the conditions fail, cancel the operation and return without executing run

    // ⚠️ LOG: operation has started
    execute(completion: finish)
  }

  open func execute(completion: @escaping (Output) -> Void) {
    preconditionFailure("Subclasses must implement `execute`.")
  }

  // Override points

  // A subclass will probably need to override -operationDidStart and -operationWillFinish
  // to set up and tear down its run loop sources, respectively.  These are always called
  // on the actual run loop thread.
  //
  // Note that -operationWillFinish will be called even if the operation is cancelled.
  //
  // -operationWillFinish can check the error property to see whether the operation was
  // successful.  error will be NSCocoaErrorDomain/NSUserCancelledError on cancellation.
  //
  // -operationDidStart is allowed to call -finishWithError:.

  open func cleanup() {
    // At this point the operation is about to be finished, the result is already populated and can be checked
    //preconditionFailure("Subclasses must implement `cleanup`.")
  }


  private let lock = NSLock() // TODO

  open override func cancel() {
    super.cancel()
    // ⚠️ LOG: operation has been cancelled
  }

  /// Call this function to finish an operation that is currently executing.
  /// State can also be "ready" here if the operation was cancelled before it started.
  public final func finish(result: Output) {
    lock.lock()
    defer { lock.unlock() }

    switch state {
    case .ready, .executing:
      self.output = result
      // ⚠️ LOG: operation is finishing
      cleanup()
      state = .finished
      // ⚠️ LOG: operation has finished
    case .finished:
      return
    }

    //    if isFinished {
    //      print("‼️‼️‼️‼️‼️‼️‼️‼️")
    //      return
    //    } else if isExecuting || isReady {
    //      self.result = result
    //      cleanup()
    //      state = .finished
    //    } else {
    //      assert(true) // TODO remove this: it's just for test purposes
    //    }
  }

  open override var description: String {
    return debugDescription
  }

  open override var debugDescription: String {
    return "\(type(of: self)) — \(name ?? "nil") – \(isCancelled ? "cancelled" : String(describing: state))"
  }
}

extension AsynchronousOperation {
  /// Mirror of the possible states an (NS)Operation can be in
  private enum State: Int, CustomStringConvertible {
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

    func canTransition(to newState: State) -> Bool {
      switch (self, newState) {
      case (.ready, .executing): return true
      case (.ready, .finished): return true // investigate (start after a cancel)
      case (.executing, .finished): return true
      default: return false
      }
    }
  }

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
        // Retrieve the existing value first. Necessary for sending fine-grained KVO
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
}

extension Operation {
  var hasSomeCancelledDependencies: Bool {
    dependencies.filter { $0.isCancelled }.count > 0
  }
}

extension NSError {
  static let notStarted = NSError(domain: identifier, code: 1, userInfo: nil)
  static let cancelled = NSError(domain: identifier, code: 2, userInfo: nil)
}

