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

  private(set) var errors = [Error]()

  private var _executing = false {
    willSet {
      willChangeValue(forKey: ObservableKey.isExecuting)
    }
    didSet {
      if _executing {
        didStart()
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

  // MARK: - Initialization

  public override init() {
    super.init()
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
    willCancel()
    super.cancel()
    didCancel()
  }

  public func finish(errors: [Error] = []) {
    self.errors.append(contentsOf: errors)
  // avoid unnecessay KVO firings.
    if _executing {
      _executing = false
    }
    if !_finished {
     _finished = true // this will fire the completionBlock via KVO
    }
  }

  // MARK: - Observer

  private(set) var observers = [OperationObserving]()

  public func addObserver(observer: OperationObserving) {
    assert(!isExecuting, "Cannot modify observers after execution has begun.")

    observers.append(observer)
  }

  private func didStart() {
    for observer in observers {
      observer.operationDidStart(operation: self)
    }
  }

  private func didFinish() {
    for observer in observers {
      observer.operationDidFinish(operation: self, withErrors: errors)
    }
  }

  private func willCancel() {
    for observer in observers {
      observer.operationWillCancel(operation: self, withErrors: errors)
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
