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

/*
import Foundation

public enum ConditionResult {

  /// Indicates that the condition is satisfied
  case satisfied

  /// Indicates that the condition failed, but can be ignored
  case ignored

  /// Indicates that the condition failed with an associated error.
  case failed
  //case failed(Error)
}

public class Condition: Hashable & Equatable {

  public var hashValue: Int {
    return category.hashValue ^ mutuallyExclusive.hashValue &* 16777619
  }

  public static func == (lhs: Condition, rhs: Condition) -> Bool {
    return (lhs.category == rhs.category) && (rhs.mutuallyExclusive == rhs.mutuallyExclusive)
  }

  internal weak var operation: AdvancedOperation? = .none

  public var category: String { return String(describing: type(of: self)) }

  public var mutuallyExclusive = false

  public func evaluate() -> ConditionResult {
    assertionFailure("ConditionOperation must be subclassed, and \(#function) overridden.")
    return .ignored
  }
}

final public class MutuallyExclusiveCondition<T>: Condition {
  public override init() {
    super.init()
    //category = "MutuallyExclusiveCondition<\(T.self)>"
    mutuallyExclusive = true
  }

  public override func evaluate() -> ConditionResult {
    return .satisfied
  }
}

final public class NotFailedDependencyCondition: Condition {
  public override init() {
    super.init()
    //category = "MutuallyExclusiveCondition<\(T.self)>"
    mutuallyExclusive = true
  }

  public override func evaluate() -> ConditionResult {
    guard let operation = operation else {
      return .ignored // TODO, missing evaluating operation
    }
    let advancedOperations = operation.dependencies.compactMap { $0 as? AdvancedOperation }
    let finishedWithErrors = advancedOperations.filter { $0.isFinished && $0.errors.count > 0 }
    let cancelledWithErrors = advancedOperations.filter { $0.isCancelled && $0.errors.count > 0 }

    if !finishedWithErrors.isEmpty || !cancelledWithErrors.isEmpty {
      return .failed
    }
    return .satisfied
  }
}
*/
