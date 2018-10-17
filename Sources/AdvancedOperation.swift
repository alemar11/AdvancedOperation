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

/// An advanced subclass of `Operation`.
open class AdvancedOperation: Operation {

  // MARK: - State

  public final override var isReady: Bool {
    switch state {

    case .pending:
      //      if isCancelled {
      //        return true
      //      }

      if super.isReady {
        evaluateConditions()
        return false
      }

      return false // Until conditions have been evaluated

    case .ready:
      return super.isReady

    default:
      return false
    }

  }

  public final override var isExecuting: Bool { return state == .executing }

  public final override var isFinished: Bool { return state == .finished }

  public final override var isCancelled: Bool { return stateLock.synchronized { return _cancelled && state != .evaluating } }

  internal final var isCancelling: Bool { return stateLock.synchronized { return _cancelling } }

  // MARK: - OperationState

  @objc
  internal enum OperationState: Int, CustomDebugStringConvertible {

    case ready
    case pending
    case evaluating
    case executing
    case finishing
    case finished

    func canTransition(to state: OperationState) -> Bool {
      switch (self, state) {
      case (.ready, .executing):
        return true
      case (.ready, .pending):
        return true
      case (.ready, .finishing): // early bailing out
        return true
      case (.pending, .evaluating):
        return true
      case (.evaluating, .ready):
        return true
      case (.executing, .finishing):
        return true
      case (.finishing, .finished):
        return true
      default:
        return false
      }
    }

    var debugDescription: String {
      switch self {
      case .ready:
        return "ready"
      case .pending:
        return "pending"
      case .evaluating:
        return "evaluating conditions"
      case .executing:
        return "executing"
      case .finishing:
        return "finishing"
      case .finished:
        return "finished"
      }
    }

  }

  // MARK: - Properties

  /// Errors generated during the execution.
  public var errors: [Error] {
      return _errors.all
  }

  /// An instance of `OSLog` (by default is disabled).
  public private(set) var log = OSLog.disabled

  /// Returns `true` if the `AdvancedOperation` has generated errors during its lifetime.
  public var hasErrors: Bool { return stateLock.synchronized { !errors.isEmpty } }

  /// A lock to guard reads and writes to the `_state` property
  private let stateLock = NSRecursiveLock()

  /// Private backing stored property for `state`.
  private var _state: OperationState = .ready

  /// Returns `true` if the finish command has been fired and the operation is processing it.
  private var _finishProcessRunning = false

  /// Returns `true` if the `AdvancedOperation` is cancelling.
  private var _cancelling = false

  /// Returns `true` if the `AdvancedOperation` is cancelled.
  @objc
  private var _cancelled = false

  /// Errors generated during the execution.
  private let _errors = SynchronizedArray<Error>()

  /// The state of the operation.
  @objc dynamic
  internal var state: OperationState {
    get { return stateLock.synchronized { _state } }
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
    case #keyPath(Operation.isCancelled):
      return Set([#keyPath(state), #keyPath(_cancelled)])
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

    // Do not start if it's finishing
    guard state != .finishing else {
      return
    }

    // Bail out early if cancelled or if there are some errors.
    guard !hasErrors && !isCancelled else {
      _cancelled = true // an operation not yet cancelled but starting with errors should finish as cancelled
      finish() // fires KVO
      return
    }

    let canBeExecuted = stateLock.synchronized { () -> Bool in
      guard isReady else { return false }

      guard !isExecuting else { return false }

      state = .executing // recursive lock
      return true
    }

    guard canBeExecuted else { return }

    willExecute()
    main()
  }

  open override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }

  open func cancel(error: Error? = .none) {
    if let error = error {
      _cancel(errors: [error])
    } else {
      _cancel()
    }
  }

  open func cancel(errors: [Error]? = .none) {
    _cancel(errors: errors)
  }

  open override func cancel() {
    _cancel()
  }

  private final func _cancel(errors cancelErrors: [Error]? = nil) {
    let canBeCancelled = stateLock.synchronized { () -> Bool in
      guard !_finishProcessRunning && !isFinished else { return false }
      guard !_cancelling && !_cancelled else { return false }

      _cancelling = true
      return true
    }

    guard canBeCancelled else { return }

    var localErrors = self.errors
    if let cancelErrors = cancelErrors {
      localErrors.append(contentsOf: cancelErrors)
    }

    willChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))
    willCancel(errors: localErrors) // observers

    stateLock.synchronized {
      if let cancelErrors = cancelErrors {
        self._errors.append(contentsOf: cancelErrors)
      }
      if _state == .pending { // conditions will not be evaluated anymore
        _state = .ready
      }
      _cancelled = true
      _cancelling = false
    }

    didCancel(errors: errors) // observers
    didChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))

    super.cancel() // fires isReady KVO
  }

  open func finish(errors: [Error] = []) {
    _finish(errors: errors)
  }

  private final func _finish(errors: [Error] = []) {
    let canBeFinished = stateLock.synchronized { () -> Bool in
      guard _state == .ready || _state == .executing else {
        return false
      }

      _state = .finishing
      _finishProcessRunning = true
      return true
    }

    guard canBeFinished else { return }

    let updatedErrors = stateLock.synchronized { () -> [Error] in
      self._errors.append(contentsOf: errors)
      return self.errors
    }

    willFinish(errors: updatedErrors)
    state = .finished
    didFinish(errors: updatedErrors)
    stateLock.synchronized { _finishProcessRunning = false }
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

  /// Indicate to the operation running on a `AdvancedOperationQueue` that it can proceed with evaluating conditions (if it's not cancelled or finished).
  internal func willEnqueue() {
    guard !isCancelled else { return } // if it's cancelled, there's no point in evaluating the conditions

    let canBeEnqueued = stateLock.synchronized { () -> Bool in
      return state == .ready
    }

    guard canBeEnqueued else { return }

    state = .pending
  }

  public func addCondition(_ condition: OperationCondition) {
    assert(state == .ready || state == .pending, "Cannot add conditions if the operation is \(state).")

    conditions.append(condition)
  }

  private func evaluateConditions() {
    let canBeEvaluated = stateLock.synchronized { () -> Bool in
      guard state == .pending else { return false }

      state = .evaluating
      return true
    }

    guard canBeEvaluated else { return }

    willEvaluateConditions()

    type(of: self).evaluate(conditions, operation: self) { [weak self] errors in
      guard let self = self else {
        return
      }

      self._errors.append(contentsOf: errors)
      self.didFinishConditionsEvaluation(errors: errors)
      self.state = .ready
    }
  }

  // MARK: - Subclass

  /// Subclass this method to know when the operation will start executing.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillExecute() {
    os_log("%{public}s has started.", log: log, type: .info, operationName)
  }

  /// Subclass this method to know if the operation has finished the evaluation of its conditions.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidFinishConditionsEvaluation(errors: [Error]) {
    os_log("%{public}s has failed the conditions evaluation with %{public}d errors.", log: log, type: .info, operationName, errors.count)
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

  internal var didFinishConditionsEvaluationObservers: [OperationDidFinishConditionsEvaluationsObserving] {
    return observers.compactMap { $0 as? OperationDidFinishConditionsEvaluationsObserving }
  }

  private func willEvaluateConditions() {
    operationWillEvaluateConditions()
  }

  private func didFinishConditionsEvaluation(errors: [Error]) {
    operationDidFinishConditionsEvaluation(errors: errors)

    for observer in didFinishConditionsEvaluationObservers {
      observer.operationDidFailConditionsEvaluations(operation: self, withErrors: errors)
    }
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

  private static func evaluate(_ conditions: [OperationCondition], operation: AdvancedOperation, completion: @escaping ([Error]) -> Void) {
    let conditionGroup = DispatchGroup()
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
    let lock = NSLock()

    // Even if an operation is cancelled, the conditions are evaluated nonetheless.
    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        lock.synchronized {
          results[index] = result
        }

        conditionGroup.leave()
      }
    }

    conditionGroup.notify(queue: DispatchQueue.global()) {
      // Aggregate all the occurred errors.
      let errors = results.compactMap { result -> [Error]? in
        if case .failed(let errors)? = result {
          return errors
        }
        return nil
      }

      let flattenedErrors = errors.flatMap { $0 }

      //      if operation.isCancelled {
      //        var aggregatedErrors = operation.errors
      //        let error = AdvancedOperationError.executionCancelled(message: "Operation cancelled while evaluating its conditions.")
      //        errors.append(contentsOf: aggregatedErrors)
      //      }
      completion(flattenedErrors)
    }
  }

}
