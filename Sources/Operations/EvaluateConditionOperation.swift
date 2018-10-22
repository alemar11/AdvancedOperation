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

/// Operation responsible to evaluate a single `OperationCondition`.
internal final class EvaluateConditionOperation: AdvancedOperation, OperationInputHaving, OperationOutputHaving {

  internal weak var input: AdvancedOperation? = .none
  internal var output: OperationConditionResult? = .none

  let condition: OperationCondition

  internal convenience init(condition: OperationCondition, for operation: AdvancedOperation) {
    self.init(condition: condition)
    self.input = operation
  }

  internal init(condition: OperationCondition) {
    self.condition = condition
    super.init()
    self.name = condition.name
  }

  internal override func main() {
    guard let evaluatedOperation = input else {
      // TODO: add error
      output = OperationConditionResult.failed([])
      finish()
      return
    }

    condition.evaluate(for: evaluatedOperation) { [weak self] result in
      guard let self = self else {
        return
      }

      self.output = result
      let errors = result.errors ?? []
      self.finish(errors: errors)
    }
  }
}
