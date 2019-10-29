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

extension Operation {
  /// Returns the `AdvancedOperation` name or its type if the name is nil.
  public var operationName: String {
    return name ?? "\(type(of: self))"
  }

  /// Returns `true` if at least one dependency has been cancelled.
  public var hasSomeCancelledDependencies: Bool {
    dependencies.filter { $0.isCancelled }.count > 0
  }

  /// Adds a completion block to be executed after the `Operation` enters the "finished" state.
  /// If there is already a completion block, they are chained together.
  ///
  /// - Parameters:
  ///   - asEndingBlock: The block can be executed before the current completion block (`asEndingBlock` = false) or after (`asEndingBlock` = true).
  ///   - block: The block to be executed after the `Operation` enters the "finished" state.
  public func addCompletionBlock(asEndingBlock: Bool = true, block: @escaping () -> Void) {
    guard let existingBlock = completionBlock else {
      completionBlock = block
      return
    }

    completionBlock = {
      if asEndingBlock {
        existingBlock()
        block()
      } else {
        block()
        existingBlock()
      }
    }
  }

  /// Adds multiple dependencies to the operation.
  public func addDependencies(_ dependencies: [Operation]) {
    precondition(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    for dependency in dependencies {
      addDependency(dependency)
    }
  }

  /// Adds multiple dependencies to the operation.
  public func addDependencies(_ dependencies: Operation...) {
    precondition(!isExecuting, "Dependencies cannot be modified after execution has begun.")

    for dependency in dependencies {
      addDependency(dependency)
    }
  }

  /// Removes all the dependencies.
  public func removeDependencies() {
    for dependency in dependencies {
      removeDependency(dependency)
    }
  }
}


extension Sequence where Element: Operation {
  public func addDependencies(_ dependencies: Operation...) {
    forEach { $0.addDependencies(dependencies) }
  }

  public func addDependencies(_ dependencies: [Operation]) {
    forEach { $0.addDependencies(dependencies) }
  }
}

