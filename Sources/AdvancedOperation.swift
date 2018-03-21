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
  
  public final override var isReady: Bool {
    switch state {
      
    case .pending:
      if isCancelled {
        return false // TODO: or should be true?
      }
      
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
  
  // MARK: - OperationState
  
  @objc
  internal enum OperationState: Int, CustomDebugStringConvertible {
    
    case ready
    case pending
    case evaluatingConditions
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
      case (.pending, .evaluatingConditions):
        return true
      case (.evaluatingConditions, .ready):
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
      case .evaluatingConditions:
        return "evaluatingConditions"
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
  
  /// Returns `true` if the `AdvancedOperation` failed due to errors.
  public var failed: Bool { return !errors.isEmpty }
  
  /// A lock to guard reads and writes to the `_state` property
  private let lock = NSRecursiveLock()
  
  /// Private backing stored property for `state`.
  private var _state: OperationState = .ready
  
  /// Returns `true` if the `AdvancedOperation` is finishing.
  private var _finishing = false
  
  /// Returns `true` if the `AdvancedOperation` is cancelling.
  private var _cancelling = false
  
  /// The state of the operation.
  @objc dynamic
  internal var state: OperationState {
    get { return lock.synchronized { _state } }
    set {
      lock.synchronized {
        assert(_state.canTransition(to: newValue), "Performing an invalid state transition for: \(_state) to: \(newValue).")
        _state = newValue
      }
      
      switch newValue {
      case .executing:
        willExecute()
      case .finished:
        didFinish()
      default:
        break
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
  
  // MARK: - Methods
  
  public final override func start() {
    // Do not start if it's finishing or already finished
    guard (state != .finishing) || (state != .finished) else { return }
    
    // Bail out early if cancelled or there are some errors.
    guard !failed && !isCancelled else {
      finish()
      return
    }
    
    guard isReady else { return }
    guard !isExecuting else { return }
    
    state = .executing
    //Thread.detachNewThreadSelector(#selector(main), toTarget: self, with: nil)
    // https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW16
    main()
  }
  
  public override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }
  
  func cancel(error: Error? = nil) {
    let result = lock.synchronized { () -> Bool in
      guard !isCancelled else { return false }
      if !_cancelling {
        _cancelling = true
        return true
      }
      return false
    }
    
    guard result else { return }
    
    //lock.synchronized{
    if let error = error {
      errors.append(error)
    }
    //}
    
    cancel()
  }
  
  public override func cancel() {
    super.cancel()
    didCancel()
  }
  
  public final func finish(errors: [Error] = []) {
    let result = lock.synchronized { () -> Bool in
      guard state.canTransition(to: .finishing) else { return  false }
      if !_finishing {
        _finishing = true
        return true
      }
      return false
    }
    
    guard result else { return }
    
    lock.synchronized {
      state = .finishing
    }
    self.errors.append(contentsOf: errors)
    
    lock.synchronized {
      state = .finished
    }
  }
  
  // MARK: - Add Condition
  
  // Indicate to the operation that it can proceed with evaluating conditions.
  internal func willEnqueue() {
    state = .pending
  }
  
  public func addCondition(condition: OperationCondition) {
    assert(state == .ready || state == .pending, "Cannot add conditions after the evaluation (or execution) has begun.") // TODO: better assert
    
    conditions.append(condition)
  }
  
  private func evaluateConditions() {
    assert(state == .pending, "Cannot evaluate conditions in this state: \(state)")
    //lock.synchronized {
    state = .evaluatingConditions
    //}
    
    type(of: self).evaluate(conditions, operation: self) { [weak self] errors in
      self?.errors.append(contentsOf: errors)
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

// MARK: - Condition Evaluation

extension AdvancedOperation {
  
  static func evaluate(_ conditions: [OperationCondition], operation: AdvancedOperation, completion: @escaping ([Error]) -> Void) {
    let conditionGroup = DispatchGroup()
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
    
    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        results[index] = result
        conditionGroup.leave()
      }
    }
    
    conditionGroup.notify(queue: DispatchQueue.global()) {
      var errors = results.compactMap { (result) -> [Error]? in
        switch result {
        case .failed(let errors)?:
          return errors
        default:
          return nil
        }
        } .flatMap { $0 }
      
      if operation.isCancelled {
        errors.append(contentsOf: operation.errors) //TODO better error
      }
      completion(errors)
    }
  }
  
}
