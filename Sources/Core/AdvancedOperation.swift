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

import Foundation
import os.log

extension AdvancedOperation: ProgressReporting { }

/// An advanced subclass of `Operation`.
open class AdvancedOperation: Operation {

  // MARK: - Public Properties

  public final  override var isReady: Bool { return super.isReady && stateLock.synchronized { return !_cancelling } }

  public final override var isExecuting: Bool { return state == .executing }

  public final override var isFinished: Bool { return state == .finished }

  public final override var isCancelled: Bool { return stateLock.synchronized { return _cancelled } }

  open override var isAsynchronous: Bool { return true }

  public final override var isConcurrent: Bool { return isAsynchronous }

  /// Errors generated during the execution.
  public var errors: [Error] { return stateLock.synchronized { _errors } }

  /// An instance of `OSLog` (by default is disabled).
  public private(set) var log = OSLog.disabled

  /// Returns `true` if the `AdvancedOperation` has generated errors during its lifetime.
  public var hasErrors: Bool { return !errors.isEmpty }

  /// Returns the oepration progress.
  @objc
  public lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: 1)
    progress.isPausable = false
    progress.isCancellable = true
    progress.cancellationHandler = { [weak self] in
      let error = AdvancedOperationError.executionCancelled(message: "A Progress has cancelled this operation.")
      self?.cancel(errors: [error])
    }
    return progress
  }()

  /// You can use this method from within the running operation object to get a reference to the operation queue that started it.
  //// Calling this method from outside the context of a running operation typically results in nil being returned.
  public var operationQueue: OperationQueue? { return OperationQueue.current }

  // MARK: - Private Properties

  /// Absolute start and times in seconds.
  private let times = Atomic<(CFAbsoluteTime?, CFAbsoluteTime?)>(value: (nil, nil))

  /// A list of OperationObservingType.
  private(set) var observers = Atomic<[OperationObservingType]>(value: [OperationObservingType]())

  /// Errors generated during the execution.
  private var _errors = [Error]()

  /// Returns `true` if the finish command has been fired and the operation is processing it.
  private var _finishing = false

  /// Returns `true` if the `AdvancedOperation` is cancelling.
  @objc private var _cancelling = false

  /// Returns `true` if the `AdvancedOperation` is starting.
  private var _starting = false

  /// Returns `true` if the `AdvancedOperation` is cancelled.
  private var _cancelled = false

  // MARK: - State

  /// A lock to guard reads and writes to the `_state` property
  private let stateLock = UnfairLock()

  /// Private backing stored property for `state`.
  private var _state: OperationState = .pending

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
    case #keyPath(Operation.isExecuting), #keyPath(Operation.isFinished):
      return Set([#keyPath(state)])
//    case #keyPath(Operation.isReady):
//      return Set([#keyPath(_cancelling)])
    default:
      return super.keyPathsForValuesAffectingValue(forKey: key)
    }
  }

  // MARK: - Life Cycle

  deinit {
    removeDependencies()
    observers.write { $0.removeAll() }
  }

  // MARK: - Execution

  public final override func start() {
    let canBeStarted = stateLock.synchronized { () -> Bool in
      guard !_starting else { return false }

      guard !_finishing else { return false }

      guard _state == .pending else { return false }

      _starting = true
      return true
    }

    guard canBeStarted else {
      return
    }

    if isCancelled {
      // if the the cancellation event has been processed, mark the operation as finished.
      finish()
      return
    }

    times.write { $0.0 = CFAbsoluteTimeGetCurrent() }
    state = .executing
    willExecute()
    main()

    if !isAsynchronous {
      finish()
    }
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
      guard !_cancelling && !_cancelled else { return false }
      guard !_finishing || _state != .finished else { return false }

      _cancelling = true
      if !cancelErrors.isEmpty { // TSAN _swiftEmptyArrayStorage
        _errors.append(contentsOf: cancelErrors)
      }
      return true
    }

    guard canBeCancelled else {
      return
    }

    willChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))
    willCancel(errors: cancelErrors)
    stateLock.synchronized {
      _cancelled = true
    }
    didCancel(errors: errors)
    didChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))

    stateLock.synchronized {
      _cancelling = false
    }

    super.cancel() // fires isReady KVO
  }

  /// Finishes the operations with errors (if any).
  ///
  /// Use this method to complete an **isAsynchronous**/**isConcurret** operation or to complete a synchronous operation with errors.
  /// - Note: For synchronous operations it's not needed to call this method unless there are errors to register upon completion.
  open func finish(errors: [Error] = []) {
    _finish(errors: errors)
  }

  private final func _finish(errors finishErrors: [Error] = []) {
    let canBeFinished = stateLock.synchronized { () -> Bool in
      guard !_finishing else {
        return false
      }

      // an operation can be finished if:
      // 1. the operation is executing
      // 2. the operation has been started after a cancel
      guard _state == .executing || (_state == .pending && _starting && _cancelled) else {
        return false
      }

      _finishing = true
      if !finishErrors.isEmpty { // TSAN _swiftEmptyArrayStorage
        _errors.append(contentsOf: finishErrors)
      }
      return true
    }

    guard canBeFinished else {
      return
    }

    willFinish(errors: errors)
    if progress.completedUnitCount != progress.totalUnitCount {
      progress.completedUnitCount = progress.totalUnitCount
    }

    times.write { $0.1 = CFAbsoluteTimeGetCurrent() }
    state = .finished
    didFinish(errors: errors)
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
    assert(state == .pending, "Dependencies cannot be modified after execution has begun.")
    super.addDependency(operation)
  }

  // MARK: - Conditions

  public private(set) var conditions = [OperationCondition]()

  public func addCondition(_ condition: OperationCondition) {
    assert(state == .pending, "Cannot add conditions if the operation is \(state).")
    conditions.append(condition)
  }

  // MARK: - Subclass

  /// Subclass this method to know when the operation will start executing.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillExecute() {
    os_log("%{public}s has started.", log: log, type: .info, operationName)
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

  // MARK: - OSLog

  /// Logs all the states of an `AdvancedOperation`.
  ///
  /// - Parameters:
  ///   - log: an `OSLog` instance.
  public func useOSLog(_ log: OSLog) {
    self.log = log
  }

}

// MARK: - Duration

extension AdvancedOperation {

  /// The `AdvancedOperation` duration in seconds.
  /// - Note: An operation that is cancelled (and not yet finished) or not started doesn't have a duration.
  public var duration: TimeInterval? {
    let intervals = times.value

    switch (intervals.0, intervals.1) {
    case (let start?, let end?):
      return end - start
    default:
      return nil
    }

  }

}

// MARK: - Observers

extension AdvancedOperation {
  /// Add an observer to the to the operation, can only be done prior to the operation starting.
  ///
  /// - Parameter observer: the observer to add.
  /// - Requires: `self must not have started.
  public func addObserver(_ observer: OperationObservingType) {
    assert(state == .pending, "Cannot modify observers after execution has begun.")

    observers.write { $0.append(observer) }
  }

  internal var willExecuteObservers: [OperationWillExecuteObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationWillExecuteObserving } }
  }

  internal var didProduceOperationObservers: [OperationDidProduceOperationObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationDidProduceOperationObserving } }
  }

  internal var willCancelObservers: [OperationWillCancelObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationWillCancelObserving } }
  }

  internal var didCancelObservers: [OperationDidCancelObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationDidCancelObserving } }
  }

  internal var willFinishObservers: [OperationWillFinishObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationWillFinishObserving } }
  }

  internal var didFinishObservers: [OperationDidFinishObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationDidFinishObserving } }
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
