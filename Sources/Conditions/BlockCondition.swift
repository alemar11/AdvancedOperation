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

/// A Condition which will be satisfied if the block returns ´true´.
/// If the block is not satisfied, the target operation will be cancelled.
/// - Note: The block may ´throw´ an error, or return ´false´, both of which are considered as a condition failure.
//public struct BlockCondition: Condition {
//  public typealias Block = () throws -> Bool
//
//  private let block: Block
//
//  public init(block: @escaping Block) {
//    self.block = block
//  }
//
//  public func evaluate(for operation: Operation, completion: @escaping (Result<Void, Error>) -> Void) {
//    do {
//      let result = try block()
//      if result {
//        completion(.success(()))
//      } else {
//        let conditionError = NSError.conditionFailed(message: "Condition failed.",
//                                                     userInfo: ["name": name])
//        completion(.failure(conditionError))
//      }
//    } catch {
//      let conditionError = NSError.conditionFailed(message: "The BlockCondition has thrown an exception.",
//                                                   userInfo: ["name": name,
//                                                              "error": error])
//      completion(.failure(conditionError))
//    }
//  }
//}

public struct BlockCondition: Condition {
  public typealias Block = (Operation) throws -> Result<Void, Error>
  private let block: Block

  public init(block: @escaping Block) {
    self.block = block
  }

  public func evaluate(for operation: Operation, completion: @escaping (Result<Void, Error>) -> Void) {
    do {
      let result = try block(operation)
      completion(result)
    } catch {
      completion(.failure(error))
    }
  }
}

public struct NoCancelledDependeciesCondition: Condition {
  private let blockCondition = BlockCondition {
    if $0.hasSomeCancelledDependencies {
      return .failure(NSError()) // TODO
    } else {
      return .success(())
    }
  }

  public init() { }

  public func evaluate(for operation: Operation, completion: @escaping (Result<Void, Error>) -> Void) {
    blockCondition.evaluate(for: operation) { completion($0) }
  }
}

public struct NegatedCondition<T: Condition>: Condition {
  public var name: String { return "Not<\(condition.name)>" }
  private let condition: T

  public init(condition: T) {
    self.condition = condition
  }

  public func evaluate(for operation: Operation, completion: @escaping (Result<Void, Error>) -> Void) {
    let conditionName = name

    condition.evaluate(for: operation) { (result) in
      switch result {
      case .success:
        let error = NSError.conditionFailed(message: "Condition failed.",
                                            userInfo: ["condition": conditionName])
        return completion(.failure(error))
      case .failure:
        return completion(.success(()))
      }
    }
  }
}

extension Condition {
  /// Returns a condition that negates the evaluation of the current condition.
  public var negated: NegatedCondition<Self> {
    return NegatedCondition(condition: self)
  }
}
