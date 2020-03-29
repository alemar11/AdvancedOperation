//
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

public typealias AsyncResultOperation = AsynchronousResultOperation

/// An `AsynchronousOperation` subclass which produces a `Result` type output.
open class AsynchronousResultOperation<Success, Failure>: AsynchronousOperation, OutputProducingOperation, FailableOperation where Failure: Error {
  public var onOutputProduced: ((Result<Success, Failure>) -> Void)?

  public final private(set) var output: Result<Success, Failure>?

  public final var error: Failure? {
    guard let result = self.output else { return nil }

    switch result {
    case .failure(let error):
      return error
    default:
      return nil
    }
  }

  /// Call this method to set the result and finish the operation.
  public final func finish(result: Result<Success, Failure>) {
    // An assert is enough since finish(result:) is the only public method to set the output.
    // the operation will crash if finish(result:) method is called more than once (see finish() implementation).
    assert(isExecuting, "Output can only be set if \(operationName) is executing.")

    output = result
    onOutputProduced?(result)
    finish()
  }
}
