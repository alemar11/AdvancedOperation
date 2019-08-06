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

/// A condition that specifies that every dependency must finish.
/// If any dependency was cancelled, the target operation will be cancelled as well.
public struct NoCancelledDependeciesCondition: OperationCondition {
  static var noCancelledDependeciesConditionKey: String { return "NoCancelledDependeciesCondition" }

  /// Create a new `NoCancelledDependeciesCondition` element.
  public init() { }

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (Result<Void,Error>) -> Void) {
    let dependencies = operation.dependencies.filter { !($0 is ConditionEvaluatorOperation) }
    let cancellations = dependencies.filter { $0.isCancelled }

    if !cancellations.isEmpty {
      let names = cancellations.map { $0.name ?? "\(type(of: $0))" }
      let error = AdvancedOperationError.conditionFailed(message: "Some dependencies have been cancelled.",
                                                         userInfo: [operationConditionKey: self.name,
                                                                    type(of: self).noCancelledDependeciesConditionKey: names])
      completion(.failure(error))
    } else {
      completion(.success(()))
    }
  }
}
