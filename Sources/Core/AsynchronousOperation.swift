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
open class AsynchronousOperation: Operation, ProgressReporting {
  // MARK: - Public Properties

  // TODO: add a @objc dynamic isPending + tests
  // TODO: test progress cancel method
  // TODO: add a setCompletedCount method? not sure
  // TODO: make progress privte? not sure
  @objc
  public final lazy private(set) var progress: Progress = {
    let progress = Progress(totalUnitCount: 1)
    progress.isPausable = false
    progress.isCancellable = true
    progress.cancellationHandler = { [weak self] in
      self?.cancel()
    }
    return progress
  }()
  
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
        
        if let oldKeyPath = oldValue.objcKeyPath {
          willChangeValue(forKey: oldKeyPath)
        }
        if let newKeyPath = newValue.objcKeyPath {
          willChangeValue(forKey: newKeyPath)
        }
        
        _state.mutate {
          assert($0.canTransition(to: newValue), "Performing an invalid state transition from: \($0) to: \(newValue) for \(operationName).")
          $0 = newValue
        }
        
        if let oldKeyPath = oldValue.objcKeyPath {
          didChangeValue(forKey: oldKeyPath)
        }
        if let newKeyPath = newValue.objcKeyPath {
          didChangeValue(forKey: newKeyPath)
        }
      }
    }
  }
  
  // MARK: - Foundation.Operation
  
  private let startLock = UnfairLock()
  
  public final override func start() {
    startLock.lock()
    defer { startLock.unlock() }
    
    switch state {
    case .finished:
      return
    case .executing:
      fatalError("The operation \(operationName) is already executing.")
    case .pending:
      guard isReady else {
        fatalError("The operation \(operationName) is not yet ready to execute.")
      }
      
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
      
      // Investigation on how super.start() works:
      // If start() is called on a not yet ready operation, super.start() will throw an exception.
      // If start() is called multiple times from different threads, super.start() will throw an exception.
      // If start() is called on an already cancelled but noy yet executed operation, super.start() will change its state to finished.
      // The isReady value is kept to true once the Operation is finished.
      // The operation readiness is evaluated after checking if the operation is already finished.
      // (In fact, if a dependency is added once the operation is already finished no exceptions are thrown if we attempt to start the operation again
      // (silly test, I know):
      //
      // let op1 = BlockOperation()
      // let op2 = BlockOperation()
      // print(op2.isReady) // true
      // op2.start()
      // print(op2.isFinished) // true
      // op2.addDependency(op1)
      // print(op2.isReady) // false
      // op2.start() // Nothing happens (no exceptions either)
      //
      // Additional considerations:
      // If an operation has finished, calling cancel() on it won't change its isCancelled value to true.
      
      // If multiple calls are made to start() from different threads at the same time
      // setting the same state will trigger an assert in the state setter.
      // A lock isn't required.
      state = .executing
      // TODO: move these comments into the TECHNOTES.md
      if #available(iOS 13.0, iOSApplicationExtension 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
        if let currentQueue = OperationQueue.current, currentQueue.progress.totalUnitCount > 0 {
          currentQueue.progress.addChild(progress, withPendingUnitCount: 1)
        }
      } else {
        // Fallback on earlier versions
      }
      main()
      
      // At this point `main()` has already returned but it doesn't mean that the operation is finished.
      // Only calling `finish()` will finish the operation at this point.
    }
  }
  
  // MARK: - Public Methods
  
  ///  The default implementation of this method does nothing.
  /// You should override this method to perform the desired task. In your implementation, do not invoke super.
  ///  This method will automatically execute within an autorelease pool provided by Operation, so you do not need to create your own autorelease pool block in your implementation.
  /// - Note: Once the task is finished you **must** call `finish()` to complete the execution.
  open override func main() {
    preconditionFailure("Subclasses must implement `main()`.")
  }
  
  /// Finishes the operation.
  /// - Important: You should never call this method outside the operation main execution scope.
  public final func finish() {
    // State can also be "pending" here if the operation was cancelled before it was started.
    
    switch state {
    case .pending, .executing:
      if progress.completedUnitCount != progress.totalUnitCount {
       progress.completedUnitCount = progress.totalUnitCount
      }
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
    var objcKeyPath: String? {
      switch self {
      case .pending: return nil
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
