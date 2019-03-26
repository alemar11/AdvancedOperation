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

// MARK: - Condition Evaluation

internal extension AdvancedOperation {

  func makeConditionsEvaluator(queue: AdvancedOperationQueue) -> AdvancedOperation? {
    guard !conditions.isEmpty else {
      return nil
    }

    guard !(self is ConditionEvaluatorOperation) else {
      return nil
    }

    let evaluator = ConditionEvaluatorOperation(operation: self, conditions: conditions)

    // observe if self is beeing cancelled
    let willCancelObserver = WillCancelObserver { [weak evaluator] _, errors in
      guard let evaluator = evaluator else {
        return
      }

      evaluator.cancel(errors: errors)
    }

    addObserver(willCancelObserver)
    evaluator.log = log
    dependencies.forEach(evaluator.addDependency)
    addDependency(evaluator)

    return evaluator
  }

}
