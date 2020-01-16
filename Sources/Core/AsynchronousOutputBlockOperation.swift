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

import Dispatch
import Foundation

public typealias AsyncOutputBlockOperation = AsynchronousOutputBlockOperation

/// A concurrent sublcass of `AsynchronousOutputOperation` to execute a closure that can optionally produce an output.
public final class AsynchronousOutputBlockOperation<OutputType>: AsynchronousOutputOperation<OutputType> {
    /// A closure type that takes a closure as its parameter.
    public typealias Block = (@escaping (Output) -> Void) -> Void
    
    // MARK: - Private Properties
    
    private var block: Block
    
    // MARK: - Initializers
    
    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - block: The closure to run when the operation executes; the parameter passed to the block **MUST** be invoked by your code,
    ///   or else the `AsynchronousBlockOperation` will never finish executing.
    public init(block: @escaping Block) {
        self.block = block
        super.init()
        self.name = "AsynchronousOutputBlockOperation<\(OutputType.self)>"
    }
    
    /// A convenience initializer.
    ///
    /// - Parameters:
    ///   - queue: The `DispatchQueue` where the operation will run its `block`.
    ///   - block: The closure to run when the operation executes.
    /// - Note: The block is run **concurrently** on the given `queue` and must return a result type to complete.
    public convenience init(queue: DispatchQueue, block: @escaping () -> Output) {
        self.init(block: { complete in
            queue.async {
                let result = block()
                complete(result)
            }
        })
    }
    
    // MARK: - Overrides
    
    public override func execute(completion: @escaping (Output) -> Void) {
        block {
            completion($0)
        }
    }
}

