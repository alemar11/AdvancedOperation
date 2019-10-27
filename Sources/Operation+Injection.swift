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

// AdvancedOperation conforming to this protocol, requires an input to be executed.
public protocol InputRequiring: AdvancedOperation {
  associatedtype Input
  var input: Input? { get set }
}

// AdvancedOperation conforming to this protocol, produce an output once finished.
public protocol OutputProducing: AdvancedOperation {
  associatedtype Output
  var output: Output? { get set }
}

extension OutputProducing {
  /// Injects the operation's output into the given operation.
  ///
  /// - Parameter operation: The input requiring AdvancedOperation.
  @discardableResult
  public func injectOutput<E: InputRequiring>(into operation: E) -> Self where Output == E.Input {
    return injectOutput(into: operation, transform: { (output) -> E.Input? in return output })
  }
  
  /// Injects the operation's output into the given operation.
  ///
  /// - Parameter operation: The input requiring AdvancedOperation.
  /// - Parameter transform: The block that transform the outpu into a suitable input for the given operation.
  @discardableResult
  public func injectOutput<E: InputRequiring>(into operation: E, transform: @escaping (Output?) -> E.Input?) -> Self {
    precondition(operation !== self, "Cannot inject output of self into self.")
    precondition(state == .pending, "Injection cannot be done after the OutputProducing operation execution has begun.")
    precondition(operation.state == .pending, "Injection cannot be done after the InputRequiring oepration execution has begun.")
    
    let willFinishObserver = WillFinishObserver { [unowned self, unowned operation] _, error in
      if error != nil {
        let cancelError = NSError.injectionCancelled(message: "The output producing operation has finished with an error.")
        operation.cancel(error: cancelError)
      } else {
        operation.input = transform(self.output)
      }
    }
    
    let didCancelObserver = DidCancelObserver { [unowned operation] _, error in
      let cancelError = NSError.injectionCancelled(message: "The output producing operation has been cancelled.")
      operation.cancel(error: cancelError)
    }
    
    self.addObserver(didCancelObserver)
    self.addObserver(willFinishObserver)
    
    operation.addDependency(self)
    
    return self
  }
}

extension OutputProducing_NEW {
  /// Creates a new operation that passes the output of `self` into the given `AdvancedOperation`
  ///
  /// - Parameters:
  ///   - operation: The operation that needs the output of `self` to generate an output.
  ///   - requirements: A list of options that the injected input must satisfy.
  /// - Returns: Returns an *adapter* operation which passes the output of `self` into the given `AdvancedOperation`.
  public func inject<E: InputConsuming>(into operation: E, orCancel: Bool = false) -> Operation where Output == E.Input {
    let injectionOperation = BlockOperation { [unowned self, unowned operation] in
      operation.input = self.output
    }

    injectionOperation.addDependency(self)
    operation.addDependency(injectionOperation)

    return injectionOperation
  }

  public func inject<E: InputConsuming>(into operation: E, orCancel: Bool = false, transform: @escaping (Output) -> E.Input?) -> Operation {
    let injectionOperation = BlockOperation { [unowned self, unowned operation] in
      operation.input = transform(self.output)
    }

    injectionOperation.addDependency(self)
    operation.addDependency(injectionOperation)

    return injectionOperation
  }
}
