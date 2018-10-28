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

  // TODO: this can be an initializer for ConditionEvaluatorOperation
  func makeConditionsEvaluator() -> AdvancedOperation? {
    guard !conditions.isEmpty else {
      return nil
    }

    let evaluator = ConditionEvaluatorOperation(conditions: conditions, operation: self)

    let selfObserver = WillCancelObserver { [weak evaluator] operation, errors in
        guard let evaluator = evaluator else {
          return
        }

        print("🚩\(operation.operationName) has been cancelled --> cancelling \(evaluator.operationName)")
        evaluator.cancel(errors: errors)
    }

    addObserver(selfObserver)
    evaluator.useOSLog(log)

    for dependency in dependencies {
      print("🚩 adding \(dependency.operationName) as dependency for \(evaluator.operationName)")
      evaluator.addDependency(dependency)

    }
    addDependency(evaluator)

    // giving the same categories to the evaluator: it can start only when the exclusivity conditions are met
    evaluator.categories = categories

    return evaluator
  }

}
