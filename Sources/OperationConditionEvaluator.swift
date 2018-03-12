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

public protocol OperationCondition {
  /// The name of the condition.
  var name: String { get }

  /// A flag to indicate whether this condition is mutually exclusive. Meaning that only one condition can be evaluated at a time.

  /// Other `Operation` instances which have this condition will wait in a `.Pending` state - i.e. not get executed.
  var isMutuallyExclusive: Bool { get }

  //func dependency(for operation: AdvancedOperation) -> Operation?
  func evaluate(for operation: AdvancedOperation, completion: @escaping (OperationConditionResult) -> ())
}

public enum OperationConditionResult
{
  case satisfied
  case failed(NSError)

  var error: NSError?
  {
    if case .failed(let error) = self
    {
      return error
    }
    return nil
  }
}

extension OperationConditionResult: Equatable {
  public static func ==(lhs: OperationConditionResult, rhs: OperationConditionResult) -> Bool {
    switch (lhs, rhs) {
    case (.satisfied, .satisfied):
      return true
    case (.failed(let lError), .failed(let rError)) where lError == rError:
      return true
    default:
      return false
    }
  }
}

struct OperationConditionEvaluator
{
  static func evaluate(_ conditions: [OperationCondition], operation: AdvancedOperation, completion: @escaping ([NSError]) -> Void) {
    let conditionGroup = DispatchGroup()
    var results = [OperationConditionResult?](repeating: nil, count: conditions.count)

    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        results[index] = result
        conditionGroup.leave()
      }
    }

    conditionGroup.notify(queue: DispatchQueue.global()) {
      var failures = results.compactMap { $0?.error }

      if operation.isCancelled {
        failures.append(NSError()) //TODO better error
      }
      completion(failures)
    }
  }
}
