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

  open override var isAsynchronous: Bool { return true }
  public final override var isReady: Bool { return super.isReady }
  public final override var isExecuting: Bool { return state == .executing }
  public final override var isFinished: Bool { return state == .finished }
  public final override var isCancelled: Bool { return hasBeenCancelled }
  public final override var isConcurrent: Bool { return isAsynchronous }

  /// Error generated during the execution.
  public var error: Error? { return _error.value }

  /// Error generated during the execution.
  private let _error = Atomic<Error?>(nil)

  /// An instance of `OSLog` (by default is disabled).
  public var log = OSLog.disabled

  /// Returns `true` if the `AdvancedOperation` has generated an error during its lifetime.
  public var hasError: Bool { return error != nil }

  /// Returns the oepration progress.
  @objc
  public lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: 1)
    progress.isPausable = false
    progress.isCancellable = true
    progress.cancellationHandler = { [weak self] in
      let error = AdvancedOperationError.executionCancelled(message: "A Progress has cancelled this operation.")
      self?.cancel(error: error)
    }
    return progress
  }()

  /// You can use this method from within the running operation object to get a reference to the operation queue that started it.
  //// Calling this method from outside the context of a running operation typically results in nil being returned.
  public var operationQueue: OperationQueue? { return OperationQueue.current }

  // MARK: - Private Properties

  /// Absolute start and times in seconds.
  private let times = Atomic<(CFAbsoluteTime?, CFAbsoluteTime?)>((nil, nil))

  /// A list of OperationObservingType.
  let observers = Atomic([OperationObservingType]())

  /// Returns `true` if the finish command has been fired and the operation is processing it.
  private var _finishing = false

  /// Returns `true` if the cancel command has been fired and the operation is processing it.
  private var _cancelling = false

  /// A lock to synchronize the access to finish() and cancel() commands.
  private let commandsLock = UnfairLock()

  /// Serial queue for making state changes atomic under the constraint of having to send KVO willChange/didChange notifications.
  private let stateChangeQueue = DispatchQueue(label: "\(identifier).stateChange")

  private let _cancelled = Atomic(false)

  /// Returns `true` if the `AdvancedOperation` is cancelled.
  internal var hasBeenCancelled: Bool {
    get {
      return _cancelled.value
    }
    set {
      stateChangeQueue.sync {
        willChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))
        _cancelled.mutate { $0 = newValue }
        didChangeValue(forKey: #keyPath(AdvancedOperation.isCancelled))
      }
    }
  }

  /// Private backing store for `state`
  private let _state = Atomic(State.pending)

  /// The state of the operation
  internal var state: State {
    get {
      return _state.value
    }
    set {
      // A state mutation should be a single atomic transaction. We can't simply perform
      // everything on the isolation queue for `_state` because the KVO willChange/didChange
      // notifications have to be sent from outside the isolation queue. Otherwise we would
      // deadlock because KVO observers will in turn try to read `state` (by calling
      // `isReady`, `isExecuting`, `isFinished`. Use a second queue to wrap the entire
      // transaction.
      stateChangeQueue.sync {
        // Retrieve the existing value first: necessary for sending fine-grained KVO.
        // willChange/didChange notifications only for the key paths that actually change.
        let oldValue = _state.value
        guard newValue != oldValue else { return }
        if let keyPath = oldValue.objcKeyPath { willChangeValue(forKey: keyPath) }
        if let keyPath = newValue.objcKeyPath { willChangeValue(forKey: keyPath) }
        _state.mutate {
          assert($0.canTransition(to: newValue), "Performing an invalid state transition from: \(_state) to: \(newValue).")
          $0 = newValue
        }
        if let keyPath = oldValue.objcKeyPath { didChangeValue(forKey: keyPath) }
        if let keyPath = newValue.objcKeyPath { didChangeValue(forKey: keyPath) }
      }
    }
  }

  // MARK: - Life Cycle

  deinit {
    removeDependencies()
    observers.mutate { $0.removeAll() }
  }

  // MARK: - Execution

  public final override func start() {

//    // evaluate conditions
//    if !conditions.isEmpty {
//      let group = DispatchGroup()
//      group.enter()
//      AdvancedOperation.evaluateConditions(conditions, for: self) { [weak self] (error) in
//        if let e = error {
//          self!.cancel(error: error)
//        }
//        group.leave()
//      }
//
//      group.wait()
//
//      let categoriesInConditions = conditions.map { $0.mutuallyExclusiveCategories }
//      let categories = categoriesInConditions.reduce(Set<ExclusivityMode>()) { (result: Set<ExclusivityMode>, set: Set<ExclusivityMode>) -> Set<ExclusivityMode> in
//        var partialResult = result
//        partialResult.formUnion(set)
//        return partialResult
//      }
//
//      if !categories.isEmpty {
//        group.enter()
//        ExclusivityManager2.shared.lock(for: categories) {
//          // it should return an error in case of cancellation mode so that we can cancel the operation
//          group.leave()
//        }
//        group.wait()
//      }
//    }

    /// The default implementation of this method updates the execution state of the operation and calls the receiver’s main() method.
    /// This method also performs several checks to ensure that the operation can actually run.
    /// For example, if the receiver was cancelled or is already finished, this method simply returns without calling main().
    /// If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.
    print("❗️", operationName, "start")
    super.start()
    print("❗️", operationName, "after start")

    // TODO: this is called once the operation is finished or cancelled
    // but if it is cancelled we need to finish it.
    // TODO: investigate it a little more for the 4.0 release
    if isCancelled {
      // if the the cancellation event has been processed, mark the operation as finished.
      finish()
      return
    }
  }

  public final override func main() {
    print("❗️", operationName, "main")
    times.mutate { $0.0 = CFAbsoluteTimeGetCurrent() }

    evaluateConditions()
    guard !isCancelled else { return }

    evaluateMutuallyExclusiveness()

    willExecute()
    state = .executing
    didExecute()
    execute()

    if !isAsynchronous {
      finish()
    }
  }

  open func execute() {
    fatalError("\(type(of: self)) must override `execute()`.")
  }

  open func cancel(error: Error? = nil) {
    _cancel(error: error)
  }

  open override func cancel() {
    _cancel()
  }

  private final func _cancel(error cancelError: Error? = nil) {
    let canBeCancelled = commandsLock.synchronized { () -> Bool in
      guard !_cancelling && !hasBeenCancelled else { return false }
      guard !_finishing || state != .finished else { return false }

      _cancelling = true
      
      if let cancelError = cancelError {
        _error.mutate { $0 = cancelError }
      }
      return true
    }

    guard canBeCancelled else {
      return
    }

    willCancel(error: cancelError)
    hasBeenCancelled = true
    didCancel(error: cancelError)

    super.cancel() // it does nothing except firing (super) isReady KVO

    commandsLock.synchronized {
      _cancelling = false
    }
  }

  /// Finishes the operation.
  ///
  /// Use this method to complete an **isAsynchronous**/**isConcurrent** operation or to complete a synchronous operation with an error.
  /// - Note: For synchronous operations it's not needed to call this method unless there is an error to register upon completion.
  open func finish(error: Error? = nil) {
    _finish(error: error)
  }

  private final func _finish(error finishError: Error?) {
    print("❗️", operationName, "_finish")
    let canBeFinished = commandsLock.synchronized { () -> Bool in
      guard !_finishing else {
        return false
      }

      // An operation can be finished if:
      // 1. the operation is executing
      // 2. the operation has been started after a cancel
      guard state == .executing || (state == .pending && hasBeenCancelled) else {
        return false
      }

      _finishing = true

      if let finishError = finishError {
        _error.mutate { error in // if the operation has been cancelled due to an error, keep that error
          if error == nil {
            error = finishError
          }
        }
      }

      return true
    }

    guard canBeFinished else {
      return
    }

    willFinish(error: error)
    // the operation is finished, the progress should always reflect that
    if progress.completedUnitCount != progress.totalUnitCount {
      progress.completedUnitCount = progress.totalUnitCount
    }

    times.mutate { $0.1 = CFAbsoluteTimeGetCurrent() }
    state = .finished
    didFinish(error: error)


    if !mutuallyExclusiveCategories.isEmpty {
      ExclusivityManager2.shared.unlock(categories: mutuallyExclusiveCategories)
    }

    commandsLock.synchronized {
      _finishing = false
    }
  }

  // MARK: - Produced Operations

  /// Produces another operation on the same `AdvancedOperationQueue` that this operation is on.
  ///
  /// - Parameter operation: the produced `Operation` instance.
  /// - Note: It's up to the developer to decide wheter or not the produced operation should run indipendently from the producing operation (if the queue is not serial).
  final func produceOperation(_ operation: Operation) {
    guard let queue = operationQueue as? AdvancedOperationQueue else {
      fatalError("An operation cannot produce any other operation if it's not enqueued on an AdvancedOperationQueue.") // TODO is this correct as fatal error?
      return
    }
    //precondition(operationQueue is AdvancedOperationQueue, "An operation cannot produce any other operation if it's not enqueued on an AdvancedOperationQueue.")

    didProduceOperation(operation)
    queue.addOperation(operation)
  }

  // MARK: - Dependencies

  open override func addDependency(_ operation: Operation) {
    precondition(state == .pending, "Dependencies cannot be modified after execution has begun.")

    super.addDependency(operation)
  }

  // MARK: - Conditions

  public private(set) var conditions = [OperationCondition]()

  lazy var mutuallyExclusiveCategories: Set<ExclusivityMode> = {
    let categoriesInConditions = conditions.map { $0.mutuallyExclusiveCategories }
    let categories = categoriesInConditions.reduce(Set<ExclusivityMode>()) { (result: Set<ExclusivityMode>, set: Set<ExclusivityMode>) -> Set<ExclusivityMode> in
      var partialResult = result
      partialResult.formUnion(set)
      return partialResult
    }
    return categories
  }()

  public func addCondition(_ condition: OperationCondition) {
    precondition(state == .pending, "Cannot add conditions if the operation is \(state).")

    conditions.append(condition)
  }

  private func evaluateConditions() {
    // evaluate conditions
    if !conditions.isEmpty {
      let group = DispatchGroup()
      group.enter()
      AdvancedOperation.evaluateConditions(conditions, for: self) { [weak self] (error) in
        if let e = error {
          self!.cancel(error: error)
        }
        group.leave()
      }

      group.wait()
    }
  }

  private func evaluateMutuallyExclusiveness() {

    if !mutuallyExclusiveCategories.isEmpty {
      let group = DispatchGroup()
      group.enter()
      ExclusivityManager2.shared.lock(for: mutuallyExclusiveCategories) {
        // it should return an error in case of cancellation mode so that we can cancel the operation
        group.leave()
      }
      group.wait()
    }
  }

  private static func evaluateConditions(_ conditions: [OperationCondition], for operation: AdvancedOperation, completion: @escaping (Error?) -> Void) {
    let conditionGroup = DispatchGroup()
    var results = [Result<Void,Error>?](repeating: nil, count: conditions.count)
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

    conditionGroup.notify(queue: DispatchQueue.global()) {
      // Aggregate all the occurred errors.
      let errors = results.compactMap { $0?.failure }
      if errors.isEmpty {
        completion(nil)
      } else {
        let aggregateError = AdvancedOperationError.conditionsEvaluationFinished(message: "\(operation.operationName) didn't pass the conditions evaluation.", errors: errors)
        completion(aggregateError)
      }
    }
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
  open func operationWillCancel(error: Error?) {
    os_log("%{public}s is cancelling.", log: log, type: .info, operationName)
  }

  /// Subclass this method to know when the operation has been cancelled.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidCancel(error: Error?) {
    if error != nil {
      os_log("%{public}s has been cancelled.", log: log, type: .info, operationName)
    } else {
      os_log("%{public}s has been cancelled with an error.", log: log, type: .info, operationName)
    }
  }

  /// Subclass this method to know when the operation will finish its execution.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationWillFinish(error: Error?) {
    if error != nil {
      os_log("%{public}s is finishing.", log: log, type: .info, operationName)
    } else {
      os_log("%{public}s is finishing with an error.", log: log, type: .info, operationName)
    }
  }

  /// Subclass this method to know when the operation has finished executing.
  /// - Note: Calling the `super` implementation will keep the logging messages.
  open func operationDidFinish(error: Error?) {
    if error != nil {
      os_log("%{public}s has finished.", log: log, type: .info, operationName)
    } else {
      os_log("%{public}s has finished with an error.", log: log, type: .info, operationName)
    }
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
    precondition(state == .pending, "Cannot modify observers after execution has begun.")

    observers.mutate { $0.append(observer) }
  }

  internal var willExecuteObservers: [OperationWillExecuteObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationWillExecuteObserving } }
  }

  internal var didExecuteObservers: [OperationDidExecuteObserving] {
    guard !observers.read ({ $0.isEmpty }) else { // TSAN _swiftEmptyArrayStorage
      return []
    }
    return observers.read { $0.compactMap { $0 as? OperationDidExecuteObserving } }
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

  private func didExecute() {
    for observer in didExecuteObservers {
      observer.operationDidExecute(operation: self)
    }
  }

  private func didProduceOperation(_ operation: Operation) {
    operationDidProduceOperation(operation)

    for observer in didProduceOperationObservers {
      observer.operation(operation: self, didProduce: operation)
    }
  }

  private func willFinish(error: Error?) {
    operationWillFinish(error: error)

    for observer in willFinishObservers {
      observer.operationWillFinish(operation: self, withError: error)
    }
  }

  private func didFinish(error: Error?) {
    operationDidFinish(error: error)

    for observer in didFinishObservers {
      observer.operationDidFinish(operation: self, withError: error)
    }
  }

  private func willCancel(error: Error?) {
    operationWillCancel(error: error)

    for observer in willCancelObservers {
      observer.operationWillCancel(operation: self, withError: error)
    }
  }

  private func didCancel(error: Error?) {
    operationDidCancel(error: error)

    for observer in didCancelObservers {
      observer.operationDidCancel(operation: self, withError: error)
    }
  }
}
