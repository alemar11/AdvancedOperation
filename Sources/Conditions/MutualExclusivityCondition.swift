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

/// A condition that defines how an operation should be added to an `AdvancedOperationQueue`.
public struct MutualExclusivityCondition: OperationCondition {

  public enum Mode {
    /// If there is already an operation with the same identifier, the new one will be cancelled.
    case cancel(identifier: String)
    /// If there is already an operation with the same identifier, the new one will be added as a dependency of the oldest one.
    case enqueue(identifier: String)
  }

  public let mode: Mode

  public init(mode: Mode) {
    self.mode = mode
  }

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    completion(.satisfied)
  }

}

extension MutualExclusivityCondition: Equatable {
  public static func == (lhs: MutualExclusivityCondition, rhs: MutualExclusivityCondition) -> Bool {
    switch (lhs.mode, rhs.mode) {
    case (.cancel(let lhsId), .cancel(let rhsId)) where lhsId == rhsId:
      return true
    case (.enqueue(let lhsId), .enqueue(let rhsId)) where
      lhsId == rhsId: return true
    default: return false
    }
  }

}
