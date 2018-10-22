//
// AdvancedOperation
//
// Copyright © 2016-2018 Tinrobots.
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

// TODO: cancel conditions evaluation if the operation is cancelled?
// TODO: better move exclusivity manager to the dependencies if any

/// An advanced subclass of `Operation`.
open class AdvancedOperation: Operation {

  // MARK: - State

  public final override var isExecuting: Bool { return state == .executing }
  public final override var isFinished: Bool { return state == .finished }
  public final override var isCancelled: Bool { return stateLock.synchronized { return _cancelled } }

  internal final var isCancelling: Bool { return stateLock.synchronized { return _cancelling } }
  internal final var isFinishing: Bool { return stateLock.synchronized { return _finishing } }
  internal final var isStarting: Bool { return stateLock.synchronized { return _starting } }

  public var categories = Set<String>()

  // MARK: - OperationState

  @objc
  internal enum OperationState: Int, CustomDebugStringConvertible {

    case ready
    case executing
    case finished

    func canTransition(to state: OperationState) -> Bool {
      switch (self, state) {
      case (.ready, .executing):
        return true
      case (.ready, .finished): // early bailing out
        return true
      case (.executing, .finished):
        return true
      default:
        return false
      }
    }

    var debugDescription: String {
      switch self {
      case .ready:
        return "ready"
      case .executing:
        return "executing"
      case .finished:
        return "finished"
      }
    }

  }

  // MARK: - Properties

  /// Errors generated during the execution.
  public var errors: [Error] { return stateLock.synchronized { _errors } }

  /// An instance of `OSLog` (by default is disabled).
  public private(set) var log = OSLog.disabled

  /// Returns `true` if the `AdvancedOperation` has generated errors during its lifetime.
  public var hasErrors: Bool { return !errors.isEmpty }

  /// A lock to guard reads and writes to the `_state` property
  private let stateLock = NSRecursiveLock()

  /// Private backing stored property for `state`.
  private var _state: OperationState = .ready

  /// Returns `true` if the finish command has been fired and the operation is processing it.
  private var _finishing = false

  /// Returns `true` if the `AdvancedOperation` is cancelling.
  private var _cancelling = false

  private var _starting = false

  /// Returns `true` if the `AdvancedOperation` is cancelled.
  private var _cancelled = false

  /// Errors generated during the execution.
  private var _errors = [Error]()

  /// The state of the operation.
  @objc dynamic
  internal var state: OperationState {
    get {
      return stateLock.synchronized { _state }
    }
    set {
      stateLock.synchronized {
        assert(_state.canTransition(to: newValue), "Performing an invalid state transition for: \(_state) to: \(newValue).")
        _state = newValue
      }
    }
  }

  open override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    switch key {
    case #keyPath(Operation.isReady),
         #keyPath(Operation.isExecuting),
         #keyPath(Operation.isFinished):
      return Set([#keyPath(state)])
    default:
      return super.keyPathsForValuesAffectingValue(forKey: key)
    }
  }

  // MARK: - Life Cycle

  deinit {
    for dependency in dependencies {
      removeDependency(dependency)
    }
  }

  // MARK: - Observers

  private(set) var observers = SynchronizedArray<OperationObservingType>()

  // MARK: - Execution

  public final override func start() {
    let canBeStarted = stateLock.synchronized { () -> Bool in
      guard !_starting else { return false }

      _starting = true
      return true
    }

    guard canBeStarted else {
      return
    }

    // Do not start if it's finishing or it's finished
    guard !isFinishing || !isFinished else {
      return
    }

    // Bail out early if cancelled or if there are some errors.
    let shouldBeFinished = stateLock.synchronized { () -> Bool in
      if !_errors.isEmpty || _cancelled {
         _cancelled = true // if there are errors, the operation should be considered as cancelled
        return true
      }
      return false
    }

    guard !shouldBeFinished else {
      finish()
      return
    }

//    guard !hasErrors && !isCancelled else {
//      _cancelled = true // an operation starting with errors should finish as cancelled
//      finish() // fires KVO
//      return
//    }

    let canBeExecuted = stateLock.synchronized { () -> Bool in
      guard _state == .ready else { return false }
      return true
    }

    guard canBeExecuted else { return }

    state = .executing
    stateLock.synchronized {
      _starting = false
    }

    willExecute()
    main()
  }

  open override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }

  open func cancel(errors: [Error] = []) {
    _cancel(errors: errors)
  }

  open override func cancel() {
    _cancel()
  }

  private final func _cancel(errors cancelErrors: [Error] = []) {
    let canBeCancelled = stateLock.synchronized { () -> Bool in
      guard !_cancelling else { return false }
      guard !_cancelled else { return false }
      guard !_finishing else { return false }
      guard state != .finished else { return false }

      _cancelling = true
      return true
    }

    guard canBeCancelled else {
      return
    }

    willChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))
    willCancel(errors: cancelErrors) // observers

    stateLock.synchronized {
      if !cancelErrors.isEmpty {
        self._errors.append(contentsOf: cancelErrors)
      }

      _cancelled = true
      _cancelling = false
    }

    didCancel(errors: errors)
    didChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))

    super.cancel() // fires isReady KVO
  }

  open func finish(errors: [Error] = []) {
    _finish(errors: errors)
  }

  private final func _finish(errors finishErrors: [Error] = []) {
    let canBeFinished = stateLock.synchronized { () -> Bool in
      guard !_finishing else { return false }
      guard _state != .finished else { return false }

      _finishing = true
      return true
    }

    guard canBeFinished else { return }

    let updatedErrors = stateLock.synchronized { () -> [Error] in
      if !finishErrors.isEmpty { // to avoid _swiftEmptyArrayStorage race condition
      _errors.append(contentsOf: finishErrors)
      }
      return _errors
    }

    willFinish(errors: updatedErrors)
    state = .finished
    didFinish(errors: updatedErrors)
    stateLock.synchronized { _finishing = false }
  }

  // MARK: - Produced Operations

  /// Produce another operation on the same `AdvancedOperationQueue` that this instance is on.
  ///
  /// - Parameter operation: an `Operation` instance.
  final func produceOperation(_ operation: Operation) {
    didProduceOperation(operation)
  }

  // MARK: - Dependencies

  open override func addDependency(_ operation: Operation) {
    assert(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    super.addDependency(operation)
  }

  // MARK: - Conditions

  public private(set) var conditions = [OperationCondition]()

  public func addCondition(_ condition: OperationCondition) {
    assert(state == .ready, "Cannot add conditions if the operation is \(state).")
    assert(!isStarting, "Cannot add conditions while the operation is starting.")

    // TODO
    // let exclusivityConditions = operation.conditions.filter { $0.mutuallyExclusivityMode != .disabled }.compactMap { $0 as? MutuallyExclusiveCondition }
    if let exclusivityCondition = condition as? MutuallyExclusiveCondition {
      categories.insert(exclusivityCondition.name)
    } else {
      conditions.append(condition)
    }
  }

  // MARK: - Subclass

  /// Subclass this method to know when the operation will start executing.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillExecute() {
    os_log("%{public}s has started.", log: log, type: .info, operationName)
  }

  /// Subclass this method to know if the operation has completed the evaluation of its conditions.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidCompleteConditionsEvaluation(errors: [Error]) {
    os_log("%{public}s has completed the conditions evaluation with %{public}d errors.", log: log, type: .info, operationName, errors.count)
  }

  /// Subclass this method to know when the operation has produced another `Operation`.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidProduceOperation(_ operation: Operation) {
    os_log("%{public}s has produced a new operation: %{public}s.", log: log, type: .info, operationName, operation.operationName)
  }

  /// Subclass this method to know when the operation will be cancelled.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillCancel(errors: [Error]) {
    os_log("%{public}s is cancelling.", log: log, type: .info, operationName)
  }

  /// Subclass this method to know when the operation has been cancelled.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidCancel(errors: [Error]) {
    os_log("%{public}s has been cancelled with %{public}d errors.", log: log, type: .info, operationName, errors.count)
  }

  /// Subclass this method to know when the operation will finish its execution.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillFinish(errors: [Error]) {
    os_log("%{public}s is finishing.", log: log, type: .info, operationName)
  }

  /// Subclass this method to know when the operation has finished executing.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidFinish(errors: [Error]) {
    os_log("%{public}s has finished with %{public}d errors.", log: log, type: .info, operationName, errors.count)
  }

  /// Subclass this method to know when the operation will start evaluating its conditions.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillEvaluateConditions() {
    os_log("%{public}s is evaluating %{public}d conditions.", log: log, type: .info, operationName, conditions.count)
  }

}

// MARK: - OSLog

extension AdvancedOperation {

  /// Logs all the states of an `AdvancedOperation`.
  ///
  /// - Parameters:
  ///   - log: A `OSLog` instance.
  ///   - type: A `OSLogType`.
  public func useOSLog(_ log: OSLog) {
    self.log = log
  }

}

// MARK: - Observers

extension AdvancedOperation {
  /// Add an observer to the to the operation, can only be done prior to the operation starting.
  ///
  /// - Parameter observer: the observer to add.
  /// - Requires: `self must not have started.
  public func addObserver(_ observer: OperationObservingType) {
    assert(!isStarting, "Cannot modify observers after execution has begun.")
    assert(!isExecuting, "Cannot modify observers after execution has begun.")

    observers.append(observer)
  }

  internal var willExecuteObservers: [OperationWillExecuteObserving] {
    return observers.compactMap { $0 as? OperationWillExecuteObserving }
  }

  internal var didProduceOperationObservers: [OperationDidProduceOperationObserving] {
    return observers.compactMap { $0 as? OperationDidProduceOperationObserving }
  }

  internal var willCancelObservers: [OperationWillCancelObserving] {
    return observers.compactMap { $0 as? OperationWillCancelObserving }
  }

  internal var didCancelObservers: [OperationDidCancelObserving] {
    return observers.compactMap { $0 as? OperationDidCancelObserving }
  }

  internal var willFinishObservers: [OperationWillFinishObserving] {
    return observers.compactMap { $0 as? OperationWillFinishObserving }
  }

  internal var didFinishObservers: [OperationDidFinishObserving] {
    return observers.compactMap { $0 as? OperationDidFinishObserving }
  }

  private func willEvaluateConditions() {
    operationWillEvaluateConditions()
  }

  private func willExecute() {
    operationWillExecute()

    for observer in willExecuteObservers {
      observer.operationWillExecute(operation: self)
    }
  }

  private func didProduceOperation(_ operation: Operation) {
    operationDidProduceOperation(operation)

    for observer in didProduceOperationObservers {
      observer.operation(operation: self, didProduce: operation)
    }
  }

  private func willFinish(errors: [Error]) {
    operationWillFinish(errors: errors)

    for observer in willFinishObservers {
      observer.operationWillFinish(operation: self, withErrors: errors)
    }
  }

  private func didFinish(errors: [Error]) {
    operationDidFinish(errors: errors)

    for observer in didFinishObservers {
      observer.operationDidFinish(operation: self, withErrors: errors)
    }
  }

  private func willCancel(errors: [Error]) {
    operationWillCancel(errors: errors)

    for observer in willCancelObservers {
      observer.operationWillCancel(operation: self, withErrors: errors)
    }
  }

  private func didCancel(errors: [Error]) {
    operationDidCancel(errors: errors)

    for observer in didCancelObservers {
      observer.operationDidCancel(operation: self, withErrors: errors)
    }
  }
}

// MARK: - Condition Evaluation

extension AdvancedOperation {
  internal func evaluateConditions(exclusivityManager: ExclusivityManager) -> GroupOperation? {
    guard !conditions.isEmpty else {
      return nil
    }

    let evaluator = ConditionEvaluatorOperation(conditions: self.conditions, operation: self, exclusivityManager: exclusivityManager)
    let observer = BlockObserver(willFinish: { [weak self] _, errors in
      if !errors.isEmpty {
        self?.cancel(errors: errors)
      }
    })

    evaluator.addObserver(observer)
    evaluator.useOSLog(log)

    for dependency in dependencies {
      evaluator.addDependency(dependency)
    }
    addDependency(evaluator)

    // giving the same categories to the evaluator, it can only start only when the exclusivity conditions are met
    evaluator.categories = categories
    return evaluator
  }

}
