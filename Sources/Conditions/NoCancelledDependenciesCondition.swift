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

/// A condition that specifies that every dependency must finish.
/// If any dependency was cancelled, the target operation will be cancelled as well.
public struct NoCancelledDependeciesCondition: OperationCondition {

  public var name: String { return category } // TODO

  public let ignoreCancellations: Bool
  /// Initializer which takes no parameters.
  public init(ignoreCancellations: Bool = false) {
    self.ignoreCancellations = ignoreCancellations
  }

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    let dependencies = operation.dependencies
    let cancellations = dependencies.filter { $0.isCancelled }

    if !cancellations.isEmpty {
      completion(.failed([NSError(domain: "demo", code: 1, userInfo: nil)]))
    } else {
      completion(.satisfied)
    }

  }

}
