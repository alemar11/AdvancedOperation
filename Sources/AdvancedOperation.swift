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

public class AdvancedOperation: Operation {

  // MARK: - State

  open override var isReady: Bool {
    switch state {
    case .pending:
      guard isCancelled else { return false }
      if super.isReady {
        evaluateConditions()
        return false
      }
    case .ready:
      return super.isReady
    default:
      return false
    }
    return false
  }
  public final override var isExecuting: Bool { return state == .executing }
  public final override var isFinished: Bool { return state == .finished }

  //  public override var isExecuting: Bool { return _executing }
  //
  //  public override var isFinished: Bool { return _finished }
  //
  //  public override var isReady: Bool {
  //    // https://stackoverflow.com/questions/19257458/nsoperation-ready-but-not-starting-on-ios-7
  //    if !_ready {
  //      evaluateConditions() //async
  //    }
  //    return super.isReady && _ready
  //  }

  @objc
  private enum OperationState: Int {
    case ready
    case pending
    case evaluatingConditions
    case executing
    case finished

    func canTransition(to state: OperationState) -> Bool {
      switch (self, state) {
      case (.ready, .executing):
        return true
      case (.ready, .evaluatingConditions):
        return true
      case (.evaluatingConditions, .evaluatingConditions):
        return true
      case (.executing, .finished):
        return true
      default:
        return false
      }
    }
  }

  // MARK: - Properties

  /// Concurrent queue for synchronizing access to `state`.

  private let stateQueue = DispatchQueue(label: "org.tinrobots.AdvancedOperation.state", attributes: .concurrent)

  /// Private backing stored property for `state`.

  private var _state: OperationState = .ready

  /// The state of the operation

  @objc dynamic
  private var state: OperationState {
    get { return stateQueue.sync { _state } }
    set {
      //      willChangeValue(forKey: ObservableKey.isReady)
      //      willChangeValue(forKey: ObservableKey.isExecuting)
      //      willChangeValue(forKey: ObservableKey.isFinished)

      stateQueue.sync(flags: .barrier) { _state = newValue }

      switch newValue {
      case .executing:
        willExecute()
      case .finished:
        didFinish()
      default:
        do {}
      }
      //      didChangeValue(forKey: ObservableKey.isReady)
      //      didChangeValue(forKey: ObservableKey.isExecuting)
      //      didChangeValue(forKey: ObservableKey.isFinished)

    }
  }

  public override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    switch (key) {
    case ObservableKey.isReady, ObservableKey.isExecuting, ObservableKey.isFinished: return Set([#keyPath(state)])
    default: return super.keyPathsForValuesAffectingValue(forKey: key)
    }
  }

  //  @objc
  //  private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
  //    return [#keyPath(state)]
  //  }
  //
  //  @objc
  //  private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
  //    return [#keyPath(state)]
  //  }
  //
  //  @objc
  //  private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
  //    return [#keyPath(state)]
  //  }

  //  private var _ready = true {
  //    willSet {
  //      willChangeValue(forKey: ObservableKey.isReady)
  //    }
  //    didSet {
  //      didChangeValue(forKey: ObservableKey.isReady)
  //    }
  //  }
  //
  //  private var _executing = false {
  //    willSet {
  //      willChangeValue(forKey: ObservableKey.isExecuting)
  //    }
  //    didSet {
  //      if _executing {
  //        willExecute()
  //      }
  //      didChangeValue(forKey: ObservableKey.isExecuting)
  //    }
  //  }
  //
  //  private var _finished = false {
  //    willSet {
  //      willChangeValue(forKey: ObservableKey.isFinished)
  //    }
  //    didSet {
  //      if _finished {
  //        didFinish()
  //      }
  //      didChangeValue(forKey: ObservableKey.isFinished)
  //    }
  //  }

  // MARK: - Conditions

  public private(set) var conditions = [OperationCondition]() //TODO : set?

  // MARK: - Observers

  private(set) var observers = [OperationObservingType]()

  internal var willExecuteObservers: [OperationWillExecuteObserving] {
    return observers.compactMap { $0 as? OperationWillExecuteObserving }
  }

  internal var didCancelObservers: [OperationDidCancelObserving] {
    return observers.compactMap { $0 as? OperationDidCancelObserving }
  }

  internal var didFinishObservers: [OperationDidFinishObserving] {
    return observers.compactMap { $0 as? OperationDidFinishObserving }
  }

  // MARK: - Errors

  public private(set) var errors = [Error]()

  // MARK: - Initialization

  public override init() {
    super.init()
    //defer { // use defer to fire KVO
    //_ready = true

    //}
  }

  // MARK: - Methods

  public final override func start() {

    // Bail out early if cancelled or there are some errors.
    guard errors.isEmpty && !isCancelled else {
      finish()
      return
    }

    guard !isExecuting else { return }

    //    _executing = true
    //    _finished = false
    state = .executing
    //Thread.detachNewThreadSelector(#selector(main), toTarget: self, with: nil)
    // https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW16
    main()
  }

  public override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }

  func cancel(error: Error? = nil) {
    guard !isCancelled else { return }

    if let error = error {
      errors.append(error)
    }

    cancel()
  }

  public override func cancel() {
    super.cancel()
    didCancel()
  }

  fileprivate var _finishing = false
  public final func finish(errors: [Error] = []) {
    guard !_finishing else { return }
    _finishing = true

    self.errors.append(contentsOf: errors)

    state = .finished
    //      _executing = false
    //      _finished = true // this will fire the completionBlock via KVO
  }

  // MARK: - Add Condition

  public func addCondition(condition: OperationCondition) {
    assert(!isExecuting, "Cannot add conditions after execution has begun.")
    //_ready = false //TODO: add a new state
    state = .pending
    conditions.append(condition)
  }

  private func evaluateConditions() {
    state = .evaluatingConditions
    OperationConditionEvaluator.evaluate(conditions, operation: self) { [weak self] errors in
      self?.errors.append(contentsOf: errors)
      //self?._ready = true //TODO: add a new state
      self?.state = .ready
    }
  }

  // MARK: - Observer

  /// Add an observer to the to the operation, can only be done prior to the operation starting.
  ///
  /// - Parameter observer: the observer to add.
  /// - Requires: `self must not have started.
  public func addObserver(observer: OperationObservingType) {
    assert(!isExecuting, "Cannot modify observers after execution has begun.")

    observers.append(observer)
  }

  private func willExecute() {
    for observer in willExecuteObservers {
      observer.operationWillExecute(operation: self)
    }
  }

  private func didFinish() {
    for observer in didFinishObservers {
      observer.operationDidFinish(operation: self, withErrors: errors)
    }
  }

  private func didCancel() {
    for observer in didCancelObservers {
      observer.operationDidCancel(operation: self, withErrors: errors)
    }
  }

  // MARK: - Dependencies

  override public func addDependency(_ operation: Operation) {
    assert(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    super.addDependency(operation)
  }

}
