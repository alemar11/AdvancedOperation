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

internal class ExclusivityManager {

  static let sharedInstance = ExclusivityManager()

  private let queue = DispatchQueue(label: "\(identifier).\(#file)")
  private var operations: [String: [Operation]] = [:]

  func addOperation(operation: Operation, category: String) {
    _ = queue.sync(execute: {
      self._addOperation(operation, category: category)
    })
  }

  func removeOperation(_ operation: Operation, category: String) {
    queue.async {
      self._removeOperation(operation, category: category)
    }
  }

  @discardableResult
  private func _addOperation(_ operation: Operation, category: String) -> Operation? {

    //TODO: add this observer here? (and remove it from OperationQueue)
    //    operation.addObserver(DidFinishObserver { [unowned self] op, _ in
    //      self.removeOperation(op, category: category)
    //    })

    var operationsWithThisCategory = operations[category] ?? []

    let previous = operationsWithThisCategory.last

    if let previous = previous {
      operation.addDependency(previous)
      //operation.addDependencyOnPreviousMutuallyExclusiveOperation(previous)
    }

    operationsWithThisCategory.append(operation)

    operations[category] = operationsWithThisCategory

    return previous
  }

  private func _removeOperation(_ operation: Operation, category: String) {
    if
      let operationsWithThisCategory = operations[category],
      let index = operationsWithThisCategory.index(of: operation)
    {
      var mutableOperationsWithThisCategory = operationsWithThisCategory
      mutableOperationsWithThisCategory.remove(at: index)
      operations[category] = mutableOperationsWithThisCategory
    }
  }
}

//extension ExclusivityManager {
//
//  /// This should only be used as part of the unit testing
//  /// and in v2+ will not be publically accessible
//  internal func __tearDownForUnitTesting() {
//    queue.sync() {
//      for (category, operations) in self.operations {
//        for operation in operations {
//          operation.cancel()
//          self._removeOperation(operation, category: category)
//        }
//      }
//    }
//  }
//}
