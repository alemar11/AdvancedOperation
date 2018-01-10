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

class BaseOperation: Operation {

  private var _isExecuting = false
  private var _isFinished = false
  
  override var isExecuting: Bool {
    get { return _isExecuting }
    set {
      let key = #keyPath(Operation.isExecuting)
      //let key = "isExecuting"
      willChangeValue(forKey: key)
      _isExecuting = newValue
      didChangeValue(forKey: key)
    }
  }

  override var isFinished: Bool {
    get { return _isFinished }
    set {
      let key = "isFinished"
      willChangeValue(forKey: key)
      _isFinished = newValue
      didChangeValue(forKey: key)
    }
  }

  open func execute() {
    fatalError("abstract")
  }

  // Because we have overridden the start() function and specifically not called super.start() the NSOperation will continue to reside in the queue, “running”, as far as the NSOperationQueue is concerned until I set the finished property to true.
  open override func start() {
    //    guard !isExecuting || !isCancelled else { return }
    //    self.isExecuting = true

    //https://stackoverflow.com/questions/3859631/subclassing-nsoperation-to-be-concurrent-and-cancellable
    super.start()
  }

  open override func main() {
    guard isExecuting || !isCancelled else { return }
    //execution block

  }

  open override func cancel() {
    super.cancel()
  }
}
