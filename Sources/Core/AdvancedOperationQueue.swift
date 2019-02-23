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

public protocol AdvancedOperationQueueDelegate: class {
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation)
  func operationQueue(operationQueue: AdvancedOperationQueue, didAddOperation operation: Operation)

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: AdvancedOperation)
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidFinish operation: Operation, withErrors errors: [Error])
  func operationQueue(operationQueue: AdvancedOperationQueue, operationDidCancel operation: AdvancedOperation, withErrors errors: [Error])

  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillFinish operation: AdvancedOperation, withErrors errors: [Error])
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillCancel operation: AdvancedOperation, withErrors errors: [Error])
}

public extension AdvancedOperationQueueDelegate {
  func operationQueue(operationQueue: AdvancedOperationQueue, willAddOperation operation: Operation) { }
  func operationQueue(operationQueue: AdvancedOperationQueue, operationWillExecute operation: AdvancedOperation) { }
}

/// `AdvancedOperationQueue` is an `OperationQueue` subclass that implements a large number of "extra features" related to the `Operation` class.
open class AdvancedOperationQueue: OperationQueue {

  public weak var delegate: AdvancedOperationQueueDelegate? = .none

  /// Keeps track of every mutual exclusivity conditions defined in the operations running on this queue.
  internal lazy var exclusivityManager: ExclusivityManager = {
    let qos: DispatchQoS

    switch self.qualityOfService {
    case .userInteractive:
      qos = .userInteractive
    case .userInitiated:
      qos = .userInitiated
    case .utility:
      qos = .utility
    case .background:
      qos = .background
    case .`default`:
      qos = .default
    }

    let manager = ExclusivityManager(qos: qos)

    return manager
  }()

  private let lock = UnfairLock()

  open override func addOperation(_ operation: Operation) {
    lock.synchronized {
      _addOperation(operation)
    }
  }

  open override func addOperation(_ block: @escaping () -> Void) {
    lock.synchronized {
      let operation = BlockOperation(block: block)
      _addOperation(operation)
    }
  }

  open override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
    lock.synchronized {
      operations.forEach(_addOperation)

      if wait {
        waitUntilAllOperationsAreFinished()
        //        for operation in super.operations {
        //          operation.waitUntilFinished()
        //        }
      }
    }
  }

}

extension AdvancedOperationQueue {
  // swiftlint:disable:next cyclomatic_complexity
  private func _addOperation(_ operation: Operation) {
    if let operation = operation as? AdvancedOperation { /// AdvancedOperation

      let observer = BlockObserver(
        willExecute: { [weak self] (operation) in
          guard let self = self else { return }

          self.delegate?.operationQueue(operationQueue: self, operationWillExecute: operation)

        }, didProduce: { [weak self] (operation, producedOperation, indipendent) in
          guard let self = self else { return }
          
          if !indipendent {
            producedOperation.addDependency(operation)
          }
          self.addOperation(producedOperation)

        }, willCancel: { [weak self] (operation, errors) in
          guard let self = self else { return }

          self.delegate?.operationQueue(operationQueue: self, operationWillCancel: operation, withErrors: errors)

        }, didCancel: { [weak self] (operation, errors) in
          guard let self = self else { return }

          self.delegate?.operationQueue(operationQueue: self, operationDidCancel: operation, withErrors: errors)

        }, willFinish: { [weak self] (operation, errors) in
          guard let self = self else { return }

          self.delegate?.operationQueue(operationQueue: self, operationWillFinish: operation, withErrors: errors)

        }, didFinish: { [weak self] (operation, errors) in
          guard let self = self else { return }

          self.delegate?.operationQueue(operationQueue: self, operationDidFinish: operation, withErrors: errors)
        }
      )

      operation.addObserver(observer)

      if let evaluator = operation.makeConditionsEvaluator(queue: self) {
        _addOperation(evaluator)
      }

      for mutualExclusivityCondition in operation.conditions.compactMap ({ $0 as? MutualExclusivityCondition }) {
        switch mutualExclusivityCondition.mode {
        case .cancel(identifier: let identifier):
          self.exclusivityManager.addOperation(operation, category: identifier, cancellable: true)
        case .enqueue(identifier: let identifier):
          self.exclusivityManager.addOperation(operation, category: identifier, cancellable: false)
        }
      }

    } else { /// Operation
      operation.addCompletionBlock(asEndingBlock: false) { [weak self, weak operation] in
        guard let self = self, let operation = operation else {
          return
        }

        self.delegate?.operationQueue(operationQueue: self, operationDidFinish: operation, withErrors: [])
      }
    }

    delegate?.operationQueue(operationQueue: self, willAddOperation: operation)
    super.addOperation(operation)
    delegate?.operationQueue(operationQueue: self, didAddOperation: operation)
  }

}
