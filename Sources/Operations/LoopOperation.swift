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
import os.log

protocol CopyingOperation: Operation {
  func makeNew() -> Self
}

class LoopOperation<T>: AsyncOperation where T: InputConsumingOperation & OutputProducingOperation & CopyingOperation, T.Input == T.Output {
  // MARK: - Public Properties

  /// The relative amount of importance for granting system resources to the operation.
  public override var qualityOfService: QualityOfService {
    get {
      return operationQueue.qualityOfService
    }
    set {
      super.qualityOfService = newValue
      operationQueue.qualityOfService = newValue
    }
  }

  // MARK: - Private Properties

  private var initialOperation: T?

  private lazy var operationQueue: OperationQueue = {
    let queue = OperationQueue.serial()
    queue.isSuspended = true
    return queue
  }()

  private lazy var finishingOperation: BlockOperation = {
    let operation = BlockOperation()
    operation.name = "FinishingOperation<\(self.operationName)>"
     operation.completionBlock = { [weak self] in
         self?.operationQueue.isSuspended = true
         self?.finish()
       }
    return operation
  }()

  // MARK: - Initializers

  public init(operation: T) {
    self.initialOperation = operation
  }

  // MARK: - Public Methods

  public final override func main() {
    guard !isCancelled else {
      self.finish()
      return
    }
    
    let op = self.initialOperation!
    setupOperation(op, isFirstStep: true)
    operationQueue.isSuspended = false
  }

  public final override func cancel() {
    super.cancel()
    operationQueue.cancelAllOperations()
  }

  // MARK: - Private Methods

  private func setupOperation(_ operation: T, isFirstStep: Bool = false) {
    let nextStep = BlockOperation { [unowned operation, unowned self] in
      if let newInput = operation.output {
        if let loggable = self as? LoggableOperation {
          os_log("%{public}s has enqueued a new copy ✅.", log: loggable.log, type: .debug, loggable.operationName)
        }
        let newOperation = self.initialOperation!.makeNew()
        newOperation.input = newInput
        self.setupOperation(newOperation)
      } else {
        // about to finish
        if let loggable = self as? LoggableOperation {
          os_log("%{public}s has 😀😀😀😀.", log: loggable.log, type: .debug, loggable.operationName)
        }
      }
    }

    nextStep.addDependency(operation)
    finishingOperation.addDependency(nextStep)
    finishingOperation.addDependency(operation)
    operationQueue.addOperation(operation)
    operationQueue.addOperation(nextStep)
    if isFirstStep {
      operationQueue.addOperation(finishingOperation)
    }

  }

}
