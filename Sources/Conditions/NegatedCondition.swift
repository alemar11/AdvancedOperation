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

/// A condition that negates the evaluation of another condition.
public struct NegatedCondition<T: OperationCondition>: OperationCondition {

  public var name: String { return "Not<\(condition.name)>" }

  static var negatedConditionKey: String { return "NegatedCondition" }

  let condition: T

  public init(condition: T) {
    self.condition = condition
  }

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    let conditionName = self.name
    let conditionKey = type(of: self).negatedConditionKey

    condition.evaluate(for: operation) { (result) in
      switch result {
      case .satisfied:
        let name = operation.name ?? "\(type(of: operation))"
        let error = AdvancedOperationError.conditionFailed(message: "The condition has been negated.",
                                                           userInfo: [operationConditionKey: conditionName,
                                                                      conditionKey: name])
        return completion(.failed([error]))
      case .failed:
        return completion(.satisfied)
      }
    }
  }

}

extension OperationCondition {

  /// Returns a condition that negates the evaluation of the current condition.
  public var negated: NegatedCondition<Self> {
    return NegatedCondition(condition: self)
  }

}
