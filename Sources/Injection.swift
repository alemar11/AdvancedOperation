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

import Foundation

extension OutputProducing {

  @discardableResult
  public func _injectOutput<E: InputRequiring>(into operation: E) -> Self where Output == E.Input {
    return _injectOutput(into: operation, transform: { (output) -> E.Input? in return output })
  }

  @discardableResult
  public func _injectOutput<E: InputRequiring>(into operation: E, transform: @escaping (Output?) -> E.Input?) -> Self {
    // precondition is self is not started and operation is not started

    precondition(operation !== self, "Cannot inject output of self into self.")
    precondition(state == .pending, "Injection cannot be done after the OutputProducing operation execution has begun.")
    precondition(operation.state == .pending, "Injection cannot be done after the InputRequiring oepration execution has begun.")
    
    let willFinishObserver = WillFinishObserver { [unowned self] _operation, error in
      if let error = error {
        // TODO: error from injected operation
        operation.cancel(error: error)
      } else {
        // TODO error from injected operation
        operation.input = transform(self.output)
      }

    }

    let didCanceObserver = DidCancelObserver { [unowned self] _operation, error in
      // TODO: error from injected operation
      operation.cancel(error: error)
    }

    self.addObserver(didCanceObserver)
    self.addObserver(willFinishObserver)

    // TODO what about conditions?

    operation.addDependency(self)

    return self
  }
}
