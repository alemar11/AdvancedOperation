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

extension Operation {

  /// Adds a completion block to be executed after the `Operation` enters the "finished" state.
  func addCompletionBlock(block: @escaping () -> Void) {
    assert(!isExecuting, "The completion block cannot be modified after execution has begun.")

    if let existingBlock = completionBlock {
      // If there is already a completion block, they are chained together.
      completionBlock = {
        existingBlock()
        block()
      }

    } else {
      completionBlock = block
    }
    
  }

  /// Adds multiple dependencies to the operation.
  func addDependencies(dependencies: [Operation]) {
    assert(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    for dependency in dependencies {
      addDependency(dependency)
    }
  }
}
