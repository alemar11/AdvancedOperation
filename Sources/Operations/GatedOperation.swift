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

/// An operation whose the underlying operation execution depends on a the result (Bool) of a block.
///
/// Even if the same result can be achieved by running an `AdvancedOperation` with a `BlockCondition` in an `AdvancedOperationQueue`,
/// a `GatedOperation` doesn't require any queue to run.
///
/// - Note: if the result is `false` or an error is thrown, the operation will be cancelled.
open class GatedOperation<T: AdvancedOperation>: AdvancedOperation {
  public typealias Block = BlockCondition.Block

  public let operation: T
  public let gate: Block

  /// Initializes a new `GatedOperation`.
  ///
  /// - Parameters:
  ///   - operation: The `AdvancedOperation` to be run if the gate is opened.
  ///   - gate: The block which determines the operation execution.
  public init(_ operation: T, gate: @escaping Block) {
    assert(operation.isReady, "The gated operation must be ready to be executed.")
    self.gate = gate
    self.operation = operation

    super.init()

    name = "GatedOperation <\(operation.operationName)>"

    self.operation.addObserver(BlockObserver(willExecute: { (operation) in
    }, didCancel: { [weak self] (operation, _) in
      guard let self = self else {
        return
      }
      assert(self.operation === operation)
      // errors are ignored because they will be collected in the didFinish callback
      self.superCancel(errors: [])

      }, didFinish: { [weak self] (operation, errors) in
        guard let self = self else {
          return
        }

        assert(self.operation === operation)
        self.superFinish(errors: errors)
    }))
  }

  private func superCancel(errors: [Error]) {
    super.cancel(errors: errors)
  }

  private func superFinish(errors: [Error]) {
    super.finish(errors: errors)
  }

  open override func main() {
    assert(operation.isReady, "The gated operation must be ready to be executed.")
    do {
      if try gate() {
        operation.start()
      } else {
        let error = AdvancedOperationError.executionCancelled(message: "The gate has returned false.")
        cancel(error: error)
        finish()
      }
    } catch let thrownError {
      let error = AdvancedOperationError.executionCancelled(message: "The gate has thrown an exception: \(thrownError).")
      cancel(error: error)
      finish()
    }
  }

  open override func cancel(errors: [Error]?) {
    operation.cancel(errors: errors)
  }

  open override func cancel(error: Error?) {
    operation.cancel(error: error)
  }

  open override func cancel() {
    operation.cancel()
  }

  open override func finish(errors: [Error] = []) {
    operation.finish()
  }

}
