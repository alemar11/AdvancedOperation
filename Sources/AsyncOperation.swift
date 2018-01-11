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

public class AsyncOperation : Operation {

  // MARK: - State

  public override var isAsynchronous: Bool { return true }
  public override var isExecuting: Bool { return _executing }
  public override var isFinished: Bool { return _finished }
  public override var isReady: Bool { return _ready }

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
      //completionBlock?()
      return
    }

    guard !isExecuting else { return }

    _executing = true
    _finished = false

    execute()
  }

  public func execute() {
    fatalError("Subclasses must implement `execute`.")
  }

  public func finish() {
    //guard isExecuting else { return }
    _executing = false
    _finished = true
  }

}

