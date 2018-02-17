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

  public override var isExecuting: Bool { return _executing }

  public override var isFinished: Bool { return _finished }

  public override var isReady: Bool {
    // https://stackoverflow.com/questions/19257458/nsoperation-ready-but-not-starting-on-ios-7
    return super.isReady && _ready
  }

  private var _ready = true {
    willSet {
      willChangeValue(forKey: ObservableKey.isReady)
    }
    didSet {
      didChangeValue(forKey: ObservableKey.isReady)
    }
  }

  private var _executing = false {
    willSet {
      willChangeValue(forKey: ObservableKey.isExecuting)
    }
    didSet {
      if _executing {
        willExecute()
      }
      didChangeValue(forKey: ObservableKey.isExecuting)
    }
  }

  private var _finished = false {
    willSet {
      willChangeValue(forKey: ObservableKey.isFinished)
    }
    didSet {
      if _finished {
        didFinish()
      }
      didChangeValue(forKey: ObservableKey.isFinished)
    }
  }

  // MARK: - Observers

  private(set) var observers = [OperationObserving]()

  internal var willExecutedObservers: [OperationWillExecuteObserving] {
    return observers.flatMap { $0 as OperationWillExecuteObserving }
  }

  internal var didCancelObservers: [OperationDidCancelObserving] {
    return observers.flatMap { $0 as OperationDidCancelObserving }
  }

  internal var didFinishObservers: [OperationDidFinishObserving] {
    return observers.flatMap { $0 as OperationDidFinishObserving }
  }

  // MARK: - Errors

  private(set) var errors = [Error]()

  // MARK: - Initialization

  public override init() {
    super.init()
    _ready = true
  }

  // MARK: - Methods

  public final override func start() {

    // Bail out early if cancelled.
    guard !isCancelled else {
      finish()
      return
    }

    guard !isExecuting else { return }

    _executing = true
    _finished = false

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

  public func finish(errors: [Error] = []) {
    self.errors.append(contentsOf: errors)

    if _executing { // avoid unnecessay KVO firings.
      _executing = false
    }

    if !_finished {
      _finished = true // this will fire the completionBlock via KVO
    }
  }

  // MARK: - Observer

  public func addObserver(observer: OperationObserving) {
    assert(!isExecuting, "Cannot modify observers after execution has begun.")

    observers.append(observer)
  }

  private func willExecute() {
    for observer in observers {
      observer.operationWillExecute(operation: self)
    }
  }

  private func didFinish() {
    for observer in observers {
      observer.operationDidFinish(operation: self, withErrors: errors)
    }
  }

  private func didCancel() {
    for observer in observers {
      observer.operationDidCancel(operation: self, withErrors: errors)
    }
  }

  // MARK: - Dependencies

  override public func addDependency(_ operation: Operation) {
    assert(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    super.addDependency(operation)
  }

}
