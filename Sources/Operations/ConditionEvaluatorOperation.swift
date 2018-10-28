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
import os.log

/// Evalutes all the `OperationCondition`.
/// The evaluation fails if this operation, once finished, contains errors.
internal final class ConditionEvaluatorOperation: AdvancedOperation {

  private let evaluatedOperationName: String
  private let evaluatedConditions: [OperationCondition]
  private weak var evaluatedOperation: AdvancedOperation?

  init(conditions: [OperationCondition], operation: AdvancedOperation) {
    evaluatedOperationName = operation.operationName
    evaluatedConditions = conditions
    evaluatedOperation = operation

    super.init()

    name = "ConditionEvaluatorOperation<\(operation.operationName)>"
  }

  override func main() {
    if isCancelled {
      finish()
      return
    }

    guard let operation = evaluatedOperation else {
      let error = AdvancedOperationError.executionFinished(message: "The operation to evaluate \(evaluatedOperationName) doesn't exist anymore.")
      finish(errors: [error])
      return
    }

    ConditionEvaluatorOperation.evaluate(evaluatedConditions, for: operation) { [weak self] errors in
      if !errors.isEmpty {
        operation.cancel(errors: errors)
      }
      self?.finish(errors: errors)
    }

  }

  private static func evaluate(_ conditions: [OperationCondition], for operation: AdvancedOperation, completion: @escaping ([Error]) -> Void) {
    let conditionGroup = DispatchGroup()
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
    let lock = NSLock()

    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        lock.synchronized {
          results[index] = result
        }

        conditionGroup.leave()
      }
    }

    conditionGroup.notify(queue: DispatchQueue.global()) {
      // Aggregate all the occurred errors.
      let errors = results.compactMap { result -> [Error]? in
        if case .failed(let errors)? = result {
          return errors
        }
        return nil
      }

      let flattenedErrors = errors.flatMap { $0 }
      completion(flattenedErrors)
    }
  }

  override func operationWillExecute() {
    os_log("%{public}s conditions are being evaluated.", log: log, type: .info, evaluatedOperationName)
  }

  override func operationWillCancel(errors: [Error]) { }

  override func operationDidCancel(errors: [Error]) {
    os_log("%{public}s conditions have been cancelled with %{public}d errors.", log: log, type: .info, evaluatedOperationName, errors.count)
  }

  override func operationWillFinish(errors: [Error]) { }

  override func operationDidFinish(errors: [Error]) {
    os_log("%{public}s conditions have been evaluated with %{public}d errors.", log: log, type: .info, evaluatedOperationName, errors.count)
  }

}
