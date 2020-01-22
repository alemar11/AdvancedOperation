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

public typealias AsyncBlockOperation = AsynchronousBlockOperation

/// A  sublcass of `AsynchronousOperation` to execute a closure.
public final class AsynchronousBlockOperation: AsynchronousOperation {
  /// A closure type that takes a closure as its parameter.
  public typealias Block = (@escaping () -> Void) -> Void
  
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
    self.name = "\(type(of: self))"
  }
  
  // MARK: - Overrides
  
  public final override func main() {
    block {
      // TODO: test if it's leaking
      self.finish()
    }
  }
}


public final class SynchronousBlockOperation: AdvancedOperation {
  /// A closure type that takes a closure as its parameter.
  public typealias Block = () -> Void
  
  // MARK: - Private Properties
  
  private var block: Block
  
  // MARK: - Initializers
  
  /// The designated initializer.
  ///
  /// - Parameters:
  ///   - block: The closure to run when the operation executes
  public init(block: @escaping Block) {
    self.block = block
    super.init()
    self.name = "\(type(of: self))"
  }
  
  // MARK: - Overrides
  
  public final override func main() {
    block()
  }
}
