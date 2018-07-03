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

// MARK: - Function

public protocol Function : AnyObject {
  associatedtype I
  associatedtype O
  var input: I? { get set }
  var output: O? { get set }
}

/// An `AdvancedOperation` with input and output values.
public class FunctionOperation<I,O> : AdvancedOperation, Function {
  public var input: I?
  public var output: O?
}

// MARK: - Adapter

public extension AdvancedOperation {

  /// - Parameter operations: a tuple of Operations where the second one needs, as input, the output of the first one.
  /// - Returns: Returns an *adapter* operation which passes the output from the first `AdvancedOperation` into the input of the second `AdvancedOperation`, and builds dependencies so the first operation runs first, then the adapter, then second operation.
  /// - Note: The client is still responsible for adding all three blocks to a queue.
  class func adaptOperations<F:Function & AdvancedOperation, G: Function & AdvancedOperation>(_ operations: (F, G)) -> AdvancedBlockOperation where F.O == G.I {

    let adapterOperation = AdvancedBlockOperation { [unowned operation0 = operations.0, unowned operation1 = operations.1] complete in
      operation1.input = operation0.output
      complete([])
    }

    adapterOperation.addDependency(operations.0)
    operations.1.addDependency(adapterOperation)

    return adapterOperation
  }
}
