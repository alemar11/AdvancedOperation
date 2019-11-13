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

import Dispatch
import Foundation

/// A concurrent sublcass of `AsynchronousOperation` to execute a closure.
public final class AsynchronousBlockOperation<T>: AsynchronousOperation<T> {
  /// A closure type that takes a closure as its parameter.
  public typealias OperationBlock = (@escaping (OperationOutput) -> Void) -> Void

  // MARK: - Private Properties

  private var block: OperationBlock

  // MARK: - Initializers

  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes; the parameter passed to the block **MUST** be invoked by your code,
  ///   or else the `AsynchronousBlockOperation` will never finish executing.
  public init(block: @escaping OperationBlock) {
    self.block = block
    super.init()
    name = "AsynchronousBlockOperation <\(T.self)>"
  }

  /// A convenience initializer.
  ///
  /// - Parameters:
  ///   - queue: The `DispatchQueue` where the operation will run its `block`.
  ///   - block: The closure to run when the operation executes.
  /// - Note: The block is run concurrently on the given `queue` and must return a result type to complete.
  public convenience init(queue: DispatchQueue = .main, block: @escaping () -> OperationOutput) {
    self.init(block: { complete in
      queue.async {
        let result = block()
        complete(result)
      }
    })
  }

  /// A convenience initializer that creates an always succeeding `AsynchronousBlockOperation`.
  ///
  /// - Parameters:
  ///   - queue: The `DispatchQueue` where the operation will run its `block`.
  ///   - block: The closure to run when the operation executes.
  /// - Note: The block is run concurrently on the given `queue` and must return a value to complete successfully.
  public convenience init(queue: DispatchQueue = .main, block: @escaping () -> T) {
    self.init(block: { complete in
      queue.async {
        let result = block()
        complete(.success(result))
      }
    })
  }

  // MARK: - Overrides

  public override func execute(completion: @escaping (OperationOutput) -> Void) {
    guard !isCancelled else {
      completion(.failure(NSError.AdvancedOperation.cancelled))
      return
    }

    block {
      completion($0)
    }
  }
}
