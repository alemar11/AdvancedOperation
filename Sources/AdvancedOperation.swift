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

  //open override var isReady: Bool { return (state == .ready || isCancelled) && super.isReady }
  open override var isReady: Bool { return state == .ready && super.isReady }

  public final override var isExecuting: Bool { return state == .executing }

  public final override var isFinished: Bool { return state == .finished }

  // MARK: - OperationState

  @objc
  internal enum OperationState: Int, CustomDebugStringConvertible {

    case ready
    case executing
    case finishing
    case finished

    func canTransition(to state: OperationState) -> Bool {
      switch (self, state) {
      case (.ready, .executing):
        return true
      case (.ready, .finishing): // early bailing out
        return true
      case (.executing, .finishing):
        return true
//      case (.executing, .ready): // cancel
//        return true
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

  /// A flag to indicate whether this `AdvancedOperation` is mutually exclusive meaning that only one operation of this type can be evaluated at a time.
  public var isMutuallyExclusive: Bool { return !mutuallyExclusiveCategories.isEmpty }

  public var mutuallyExclusiveCategories: Set<String> { return lock.synchronized { _categories } }

  /// Returns `true` if the `AdvancedOperation` failed due to errors.
  public var failed: Bool { return lock.synchronized { !errors.isEmpty } }

  /// A lock to guard reads and writes to the `_state` property
  private let lock = NSLock()

  /// Private backing stored property for `state`.
  private var _state: OperationState = .ready

  /// Returns `true` if the `AdvancedOperation` is finishing.
  private var _finishing = false

  /// Returns `true` if the `AdvancedOperation` is cancelling.
  private var _cancelling = false

  /// Set of categories used by the ExclusivityManager.
  private var _categories = Set<String>()

  /// The state of the operation.
  @objc dynamic
  internal var state: OperationState {
    get { return lock.synchronized { _state } }
    set {
      lock.synchronized {
        assert(_state.canTransition(to: newValue), "Performing an invalid state transition for: \(_state) to: \(newValue).")
        _state = newValue
      }
    }
  }

  public override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
    switch key {
    case #keyPath(Operation.isReady),
         #keyPath(Operation.isExecuting),
         #keyPath(Operation.isFinished):
      return Set([#keyPath(state)])
    default:
      return super.keyPathsForValuesAffectingValue(forKey: key)
    }
  }

  /**
   @objc
   private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
   return [#keyPath(state)]
   }

   @objc
   private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
   return [#keyPath(state)]
   }

   @objc
   private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
   return [#keyPath(state)]
   }
   **/

  // MARK: - Observers

  private(set) var observers = [OperationObservingType]()

  internal var willExecuteObservers: [OperationWillExecuteObserving] {
    return observers.compactMap { $0 as? OperationWillExecuteObserving }
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

  // MARK: - Errors

  public private(set) var errors = [Error]()

  // MARK: - Methods

  public final override func start() {
//    let result = lock.synchronized { () -> Bool in
//        return _cancelling
//    }
//
//    guard !result else {
//      print(result)
//      return
//    }

    // Do not start if it's finishing
    guard (state != .finishing) else {
      return
    }

    // Bail out early if cancelled or there are some errors.
    guard !failed && !isCancelled else {
      finish() // fires KVO
      return
    }

    guard isReady else { return }
    guard !isExecuting else { return }

    state = .executing
    willExecute()
    //Thread.detachNewThreadSelector(#selector(main), toTarget: self, with: nil)
    // https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW16
    main()
  }

  public override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }

  public func cancel(error: Error? = nil) {
    _cancel(error: error)
  }

  public override func cancel() {
    _cancel()
  }

  private func _cancel(error: Error? = nil) {
    let result = lock.synchronized { () -> Bool in
      guard !_cancelling && !isCancelled else { return false }
      _cancelling = true
      return _cancelling
    }

    guard result else { return }

    let updatedErrors = lock.synchronized { () -> [Error] in
      if let error = error {
        self.errors.append(error)
      }
      return self.errors
    }

    willCancel(errors: updatedErrors)
    super.cancel() // fires KVO
    didCancel(errors: errors)
    lock.synchronized { _cancelling = false }
  }

  public final func finish(errors: [Error] = []) {
    let result = lock.synchronized { () -> Bool in
      guard _state.canTransition(to: .finishing) else { return false }
      _state = .finishing
      if !_finishing {
        _finishing = true
        return true
      }
      return false
    }

    guard result else { return }

    let updatedErrors = lock.synchronized { () -> [Error] in
      self.errors.append(contentsOf: errors)
      return self.errors
    }

    willFinish(errors: updatedErrors)
    state = .finished
    didFinish(errors: updatedErrors)
  }

  // MARK: - Mutually Exclusive Category

  func addMutuallyExclusiveCategory(_ category: String) {
    assert(isReady, "Invalid state \(_state) for adding mutually exclusive categories.")

    lock.synchronized {
      _categories.insert(category)
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

  private func willFinish(errors: [Error]) {
    for observer in willFinishObservers {
      observer.operationWillFinish(operation: self, withErrors: errors)
    }
  }

  private func didFinish(errors: [Error]) {
    for observer in didFinishObservers {
      observer.operationDidFinish(operation: self, withErrors: errors)
    }
  }

  private func willCancel(errors: [Error]) {
    for observer in willCancelObservers {
      observer.operationWillCancel(operation: self, withErrors: errors)
    }
  }

  private func didCancel(errors: [Error]) {
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
