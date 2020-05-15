//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

public typealias AsyncOperation = AsynchronousOperation

/// An abstract thread safe subclass of `Operation` to support asynchronous operations.
///
/// Subclasses must override `main` to perform any work and, if they are asynchronous, call the `finish()` method to complete the execution.
open class AsynchronousOperation: Operation {
  // MARK: - Public Properties

  /// A Boolean value indicating whether the async operation is currently waiting to be executed.
  /// The initial value is always *true*.
  @objc
  public dynamic final var isPending: Bool {
    return state == .pending
  }
  
  public final override var isExecuting: Bool {
    return state == .executing
  }
  
  public final override var isFinished: Bool {
    return state == .finished
  }
  
  public final override var isAsynchronous: Bool { return isConcurrent }
  
  public final override var isConcurrent: Bool { return true }
  
  // MARK: - Private Properties
  
  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).AsynchronousOperation.stateChange")
  
  /// Private backing store for `state`
  private var _state: Atomic<State> = Atomic(.pending)
  
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
          assert($0.canTransition(to: newValue), "Performing an invalid state transition from: \($0) to: \(newValue) for \(operationName).")
          $0 = newValue
        }

        didChangeValue(forKey: oldValue.objcKeyPath)
        didChangeValue(forKey: newValue.objcKeyPath)

      }
    }
  }
  
  // MARK: - Foundation.Operation

  public final override func start() {
    // early bailing out if the operation is already cancelled
    //
    // checking if the state is pending avoids calling finish() multiple times if start() gets called wrongly more than once.
    if isCancelled && state == .pending {
      finish()
    }

    // even if the documentation suggests to not call `super.start()`, as iOS 13 it contains important logic
    // for progress reporting that shouldn't be bypassed
    //
    // `super.start()` is also used to throw exceptions if the operation is misused
    super.start()
    // At this point `main()` has already returned but it doesn't mean that the operation is finished.
  }
  
  // MARK: - Public Methods

  open override func main() {
    state = .executing
    execute()
  }

  ///  The default implementation of this method does nothing.
  /// You should override this method to perform the desired task. In your implementation, do not invoke super.
  ///  This method will automatically execute within an autorelease pool provided by Operation, so you do not need to create your own autorelease pool block in your implementation.
  /// - Note: Once the task is finished you **must** call `finish()` to complete the execution.
  open func execute() {
    preconditionFailure("Subclasses must implement `execute()`.")
  }
  
  /// Finishes the operation.
  /// - Important: You should never call this method outside the operation main execution scope.
  public final func finish() {
    // State can also be "pending" here if the operation was cancelled before it was started.
    switch state {
    case .pending, .executing:
      // If multiple calls are made to finish() from different threads at the same time
      // setting the same state will trigger an assert in the state setter.
      // A lock isn't required.
      state = .finished
    case .finished:
      preconditionFailure("The finish() method shouldn't be called more than once for \(operationName).")
    }
  }
  
  // MARK: - Debug
  
  open override var description: String {
    return debugDescription
  }
  
  open override var debugDescription: String {
    return "\(operationName) – \(isCancelled ? "cancelled (\(state))" : "\(state)")"
  }
}

// MARK: - State

extension AsynchronousOperation {
  /// All the possible states an Operation can be in.
  enum State: Int, CustomStringConvertible, CustomDebugStringConvertible {
    case pending // waiting to be executed
    case executing
    case finished
    
    /// The `#keyPath` for the `Operation` property that's associated with this value.
    var objcKeyPath: String {
      switch self {
      case .pending: return #keyPath(isPending)
      case .executing: return #keyPath(isExecuting)
      case .finished: return #keyPath(isFinished)
      }
    }
    
    var description: String {
      switch self {
      case .pending: return "pending"
      case .executing: return "executing"
      case .finished: return "finished"
      }
    }
    
    var debugDescription: String {
      return description
    }
    
    func canTransition(to newState: State) -> Bool {
      switch (self, newState) {
      case (.pending, .executing): return true
      case (.pending, .finished): return true
      case (.executing, .finished): return true
      default: return false
      }
    }
  }
}
