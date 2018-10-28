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

// MARK: - Condition Evaluation

internal extension AdvancedOperation {

  func evaluateConditions(exclusivityManager: ExclusivityManager) -> [AdvancedOperation] {
    guard !conditions.isEmpty else {
      return []
    }

    let evaluator = ConditionEvaluatorOperation(conditions: conditions, operation: self, exclusivityManager: exclusivityManager)
    let producedOperations = conditions.compactMap { $0.dependency(for: self) }

    //    let evaluatorObserver = BlockObserver(willFinish: { [weak self] operation, errors in
    //      if operation.isCancelled || !errors.isEmpty {
    //        self?.cancel(errors: errors)
    //      }
    //    })

    let selfObserver = BlockObserver(
      willCancel: { [weak evaluator, producedOperations] operation, errors in
        guard let evaluator = evaluator else {
          return
        }

        print("🚩\(operation.operationName) has been cancelled --> cancelling \(evaluator.operationName) and \(producedOperations)")
        evaluator.cancel(errors: errors)
        _ = producedOperations.map { $0.cancel() }
        //}
    })

    _ = producedOperations.map { evaluator.addDependency($0) }

    print("🥇\(producedOperations.count)")

    addObserver(selfObserver)
    //evaluator.addObserver(evaluatorObserver)
    evaluator.useOSLog(log)

    for dependency in dependencies {
      print("🚩 adding \(dependency.operationName) as dependency for \(evaluator.operationName)")
      evaluator.addDependency(dependency)
      _ = producedOperations.map { $0.addDependency(dependency) }
    }
    addDependency(evaluator)
    _ = producedOperations.map { addDependency($0) } //not sure about this

    // giving the same categories to the evaluator: it can start only when the exclusivity conditions are met
    evaluator.categories = categories
    //TODO
    // add categories to producedOperations too?

    var operations = producedOperations
    operations.append(evaluator)
    return operations
  }

}
