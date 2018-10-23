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

/// A generic condition for describing kinds of operations that may not execute concurrently.
public struct MutuallyExclusiveCondition: OperationCondition {

  public let name: String

  public let mutuallyExclusivityMode: MutualExclusivityMode

  /// Creates a new `MutuallyExclusiveCondition` element.
  public init(name: String, mode: MutualExclusivityMode = .enqueue) {
    self.name = name
    self.mutuallyExclusivityMode = mode
  }

  public func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> Void) {
    completion(.satisfied)
  }

}

/// Defines the mutual exclusivity behaviour for an operation's condition.
public enum MutualExclusivityMode: CustomStringConvertible {
  /// Enabled, but only one operation can be evaluated at a time.
  case enqueue
  /// Enabled, but only one operation will be executed.
  case cancel

  public var description: String {
    switch self {
    case .enqueue: return "Enabled in enqueue mode"
    case .cancel: return "Enabled in cancel mode"
    }
  }
}


internal struct MutualExclusivityCategory: Hashable {
  let name: String
  let mode: MutualExclusivityMode
}
