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
import os.log

internal let identifier = "org.tinrobots.AdvancedOperation"

/// An abstract thread safe subclass of `Operation`.
///
/// Subclasses must override `main` to perform any work and, if they are asynchronous, call the `finish()` method to complete the execution.
open class AdvancedOperation: Operation {
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
  
  // MARK: - Private Properties
  
  /// Lock to ensure thread safety.
  private let lock = UnfairLock()
  
  private var preconditions = [Precondition]()
  
  /// An operation is considered as "running" from the `start()` method is called until it gets finished.
  private var isRunning = Atomic(false)
  
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
    guard !isFinished else { return }
    
    let isAlreadyRunning = isRunning.mutate { running -> Bool in
      if running {
        return true // already running
      } else if isReady {
        running = true
        return false // it will be considered as running from now on
      } else {
        preconditionFailure("The operation \(operationName) is not ready yet.")
      }
    }
    
    guard !isAlreadyRunning else { return }
    
    // early bailing out
    guard !isCancelled else {
      _finish()
      return
    }
    
    // Calling super.start() here causes some KVO issues (the doc says "Your (concurrent) custom implementation must not call super at any time").
    // The default implementation of this method ("start") updates the execution state of the operation and calls the receiver’s main() method.
    // This method also performs several checks to ensure that the operation can actually run.
    // For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    // If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    
    state = .executing
    
    guard !isCancelled else {
      // TODO: this check is useless as we could check the cancel status directly in the main
      // it can only help to avoid a needless preconditions evaluations
      // NOTE: this can happen if a KVO observer cancel the operation, I think that a re-entrant lock for start() cancel and _finish is the only solution
      _finish()
      return
    }

    let errors = evaluatePreconditions()
    if errors.isEmpty {
      main()
      if !isAsynchronous {
        _finish()
      }
    } else {
      cancel()
      _finish() // or we could simply finish it with an error (instead of a cancel)
    }
    
    // If asynchronous:
    // At this point main() has already returned but it doesn't mean that the operation is finished.
    // Only calling `finish()` will finish the operation at this point.
  }
  
  // MARK: - Public Methods
  
  public override func main() {
    preconditionFailure("Subclasses must implement `main`.")
  }
  
  //  open override func cancel() {
  //    // TODO: remove ?
  //    lock.lock()
  //    defer { lock.unlock() }
  //
  //    guard !isCancelled else { return }
  //
  //    super.cancel()
  //  }
  
  public final func addPrecondition(_ condition: Precondition) {
    lock.lock()
    defer { lock.unlock() }
    
    precondition(!isRunning.value, "Preconditions should be added only before executing the operation")
    preconditions.append(condition)
  }
  
  // MARK: - Private Methods
  
  /// Call this function to finish an operation that is currently executing.
  public final func finish() {
    precondition(isAsynchronous, "The finish() method cannot be called explicitly for synchronous operations.")
    _finish()
  }
  
  private final func _finish() {
    // State can also be "ready" here if the operation was cancelled before it was started.
    lock.lock()
    defer { lock.unlock() }
    
    switch state {
    case .ready, .executing:
      state = .finished
      isRunning.mutate { $0 = false }
    case .finished:
      preconditionFailure("The finish() method shouldn't be called more than once for \(operationName).")
    }
  }
  
  // MARK: - Debug
  
  open override var description: String {
    return debugDescription
  }
  
  open override var debugDescription: String {
    return "\(operationName)) – \(isCancelled ? "cancelled" : String(describing: state))"
  }
}

// MARK: - State

extension AdvancedOperation {
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

// MARK: - Precondition

extension AdvancedOperation {
  fileprivate final func evaluatePreconditions() -> [Error] {
    return Self.evaluatePreconditions(preconditions, for: self)
  }
  
  fileprivate static func evaluatePreconditions(_ preconditions: [Precondition], for operation: AdvancedOperation) -> [Error] {
    let group = DispatchGroup()
    var results = [Result<Void, Error>?](repeating: nil, count: preconditions.count)
    let lock = UnfairLock()
    
    for (index, precondition) in preconditions.enumerated() {
      group.enter()
      precondition.evaluate(for: operation) { result in
        lock.lock()
        results[index] = result
        lock.unlock()
        group.leave()
      }
    }
    
    group.wait()
    
    let errors = results.compactMap { $0?.error }
    return errors
  }
}

private extension Result {
  var error: Error? {
    switch self {
    case .failure(let error):
      return error
    case .success(_):
      return nil
    }
  }
}
