// 
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
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

public protocol Precondition {
  /// The name of the condition.
  var name: String { get }
  /// Evaluate the condition, to see if it has been satisfied or not.
  ///
  /// - Parameters:
  ///   - operation: the `AdvancedOperation` which this condition is attached to.
  ///   - completion: a closure which receives a `Result`.
  func evaluate(for operation: Operation, completion: @escaping (Result<Void, Error>) -> Void)
}

public extension Precondition {
  var name: String {
    return String(describing: type(of: self))
  }
}


protocol Preconditioned: Operation {
  var preconditions: [Precondition] { get }
}

private var preconditionKey: UInt8 = 1
extension Preconditioned {
  private(set) var preconditions: [Precondition] {
    get {
      if let preconditions = objc_getAssociatedObject(self, &preconditionKey) as? [Precondition] {
        return preconditions
      } else {
        return []
      }
    }
    set {
      objc_setAssociatedObject(self, &preconditionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  
  func addPrecondition(_ precondition: Precondition) {
    preconditions.append(precondition)
  }
  
  func evaluatePreconditions() -> [Error] {
    return Self.evaluateConditions(preconditions, for: self)
  }
  
  private static func evaluateConditions(_ conditions: [Precondition], for operation: Operation) -> [Error] {
    let conditionGroup = DispatchGroup()
    var results = [Result<Void, Error>?](repeating: nil, count: conditions.count)
    let lock = UnfairLock()
    
    for (index, condition) in conditions.enumerated() {
      conditionGroup.enter()
      condition.evaluate(for: operation) { result in
        lock.lock()
        results[index] = result
        lock.unlock()
        conditionGroup.leave()
      }
    }
    
    conditionGroup.wait()
    
    let errors = [Error]() //results.filter(<#T##isIncluded: (Result<Void, Error>?) throws -> Bool##(Result<Void, Error>?) throws -> Bool#>)
    return errors
  }
}
