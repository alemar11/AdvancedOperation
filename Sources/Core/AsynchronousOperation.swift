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
//
// https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW8
// https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html

import Foundation
import os.log

public typealias AsyncOperation = AsynchronousOperation
/// An abstract thread safe subclass of `AdvancedOperation` to build asynchronous operations.
///
/// Subclasses must override `execute(completion:)` to perform any work and call the completion handler to finish it.
///
/// To enable logging:
/// - To enable log add this environment key: `org.tinrobots.AdvancedOperation.LOG_ENABLED`
/// - To enable signposts add this environment key: `org.tinrobots.AdvancedOperation.SIGNPOST_ENABLED`
/// - To enable point of interests add this environment key: `org.tinrobots.AdvancedOperation.POI_ENABLED`
open class AsynchronousOperation: AdvancedOperation {
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
  
  public final override var isConcurrent: Bool { return isAsynchronous }
  
  // MARK: - Private Properties
  
  /// Lock to ensure thread safety.
  private let lock = UnfairLock()
  
  /// An operation is considered as "running" from the `start()` method is called until it gets finished.
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
          assert($0.canTransition(to: newValue), "Performing an invalid state transition from: \($0) to: \(newValue) for \(operationName).")
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
      finish()
      return
    }
    
    // Calling super.start() here causes some KVO issues (the doc says "Your (concurrent) custom implementation must not call super at any time").
    // The default implementation of this method ("start") updates the execution state of the operation and calls the receiver’s main() method.
    // This method also performs several checks to ensure that the operation can actually run.
    // For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    // If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    
    state = .executing
    
    // TODO: conditions here
    // - if the conditions aren't satisfied:
    //      - the operation will get cancelled
    //      - the first error will be stored
    // update: if we have at least one condition that generates an error, instead of cancelling the operaiton
    // we simply finish it with the error (in that case the isCancelled check below should be replaced
    // or we can cancel it with an error if we implement cancel(error:)
    
    if isCancelled {
      finish()
    } else {
      main()
    }
    
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
  
  // MARK: - Private Methods
  
  /// Call this function to finish an operation that is currently executing.
  public final func finish() {
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
