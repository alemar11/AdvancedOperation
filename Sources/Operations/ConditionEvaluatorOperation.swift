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
internal final class ConditionEvaluatorOperation: GroupOperation {

  private var _operationName: String

  init(conditions: [OperationCondition], operation: AdvancedOperation, exclusivityManager: ExclusivityManager) { //TODO: set
    _operationName = operation.operationName

    super.init(operations: [])

    conditions.forEach { condition in
      if condition is MutuallyExclusiveCondition {
        return
      }

      let evaluatingOperation = EvaluateConditionOperation(condition: condition, operation: operation)
      evaluatingOperation.useOSLog(log)

      if let dependency = condition.dependency(for: operation) {
        evaluatingOperation.addDependency(dependency)
        addOperation(operation: dependency)
      }

      addOperation(operation: evaluatingOperation)
    }

    name = "ConditionEvaluatorOperation<\(operation.operationName)>"
  }

  override func operationWillExecute() {
    os_log("%{public}s conditions are being evaluated.", log: log, type: .info, _operationName)
  }

  override func operationWillFinish(errors: [Error]) {
     os_log("%{public}s conditions are finishing the evaluation with %{public}d errors.", log: log, type: .info, _operationName, errors.count)
  }

  override func operationDidFinish(errors: [Error]) {
    os_log("%{public}s conditions have been evaluated with %{public}d errors.", log: log, type: .info, _operationName, errors.count)
  }

}
