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

public class AdvancedOperation : Operation {

  // MARK: - State

  //public override var isAsynchronous: Bool { return true } // When you add an operation to an operation queue, the queue ignores the value of the isAsynchronous
  
  public override var isExecuting: Bool { return _executing }
  public override var isFinished: Bool { return _finished }
  public override var isReady: Bool { return _ready }

  private(set) var errors = [Error]()

  private var _executing = false {
    willSet {
      willChangeValue(forKey: #keyPath(Operation.isExecuting))
    }
    didSet {
      didChangeValue(forKey: #keyPath(Operation.isExecuting))
    }
  }

  private var _finished = false {
    willSet {
      willChangeValue(forKey: #keyPath(Operation.isFinished))
    }
    didSet {
      didChangeValue(forKey: #keyPath(Operation.isFinished))
    }
  }

  private var _ready = false {
    willSet {
      willChangeValue(forKey: #keyPath(Operation.isReady))
    }
    didSet {
      didChangeValue(forKey: #keyPath(Operation.isReady))
    }
  }

  // MARK: Initialization

  public override init() {
    super.init()
    
    _ready = true
  }

  // MARK: - Methods

  public override func start() {
    _ready = false

    // Bail out early if cancelled.
    guard !isCancelled else {
      _finished = true // this will fire the completionBlock via KVO
      return
    }

    guard !isExecuting else { return }

    _executing = true
    _finished = false

    for observer in observers {
      observer.operationDidStart(operation: self)
    }

    //Thread.detachNewThreadSelector(#selector(main), toTarget: self, with: nil)
    // https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationObjects/OperationObjects.html#//apple_ref/doc/uid/TP40008091-CH101-SW16
    main()

  }

  public override func main() {
    fatalError("\(type(of: self)) must override `main()`.")
  }

  func cancel(error: Error? = nil) {
    if let error = error {
      errors.append(error)
    }

    cancel()
  }

  public func finish(errors: [Error] = []) {
    //guard isExecuting else { return }
    self.errors.append(contentsOf: errors)

    for observer in observers {
      observer.operationDidFinish(operation: self, errors: self.errors)
    }

    _executing = false
    _finished = true
  }

  // MARK: Observer

  private(set) var observers = [OperationObserving]()

  public func addObserver(observer: OperationObserving) {
    assert(!isExecuting, "Cannot modify observers after execution has begun.")

    observers.append(observer)
  }

  // MARK: Dependencies

  override public func addDependency(_ operation: Operation) {
    assert(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    super.addDependency(operation)
  }

}

