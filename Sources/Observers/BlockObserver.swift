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

/// The `BlockObserver` is a way to attach arbitrary blocks to significant events in an `Operation`'s lifecycle.
public class BlockObserver: OperationObserving {
  // MARK: - Properties

  private let willExecuteHandler: ((AdvancedOperation) -> Void)?
  private let didExecuteHandler: ((AdvancedOperation) -> Void)?
  private let willFinishHandler: ((AdvancedOperation, Error?) -> Void)?
  private let didFinishHandler: ((AdvancedOperation, Error?) -> Void)?
  private let willCancelHandler: ((AdvancedOperation, Error?) -> Void)?
  private let didCancelHandler: ((AdvancedOperation, Error?) -> Void)?
  private let didProduceOperationHandler: ((Operation, Operation) -> Void)?

  public init (willExecute: ((AdvancedOperation) -> Void)? = nil,
               didExecute: ((AdvancedOperation) -> Void)? = nil,
               didProduce: ((Operation, Operation) -> Void)? = nil,
               willCancel: ((AdvancedOperation, Error?) -> Void)? = nil,
               didCancel: ((AdvancedOperation, Error?) -> Void)? = nil,
               willFinish: ((AdvancedOperation, Error?) -> Void)? = nil,
               didFinish: ((AdvancedOperation, Error?) -> Void)? = nil) {
    self.willExecuteHandler = willExecute
    self.didExecuteHandler = didExecute
    self.didProduceOperationHandler = didProduce
    self.willFinishHandler = willFinish
    self.didFinishHandler = didFinish
    self.willCancelHandler = willCancel
    self.didCancelHandler = didCancel
  }

  // MARK: - OperationObserving

  public func operationWillExecute(operation: AdvancedOperation) {
    willExecuteHandler?(operation)
  }

  public func operationDidExecute(operation: AdvancedOperation) {
    didExecuteHandler?(operation)
  }

  public func operationWillFinish(operation: AdvancedOperation, withError error: Error?) {
    willFinishHandler?(operation, error)
  }

  public func operationDidFinish(operation: AdvancedOperation, withError error: Error?) {
    didFinishHandler?(operation, error)
  }

  public func operationWillCancel(operation: AdvancedOperation, withError error: Error?) {
    willCancelHandler?(operation, error)
  }

  public func operationDidCancel(operation: AdvancedOperation, withError error: Error?) {
    didCancelHandler?(operation, error)
  }

  public func operation(operation: AdvancedOperation, didProduce producedOperation: Operation) {
    didProduceOperationHandler?(operation, producedOperation)
  }
}

internal final class WillCancelObserver: OperationWillCancelObserving {
  // MARK: - Properties

  private let willCancelHandler: ((AdvancedOperation, Error?) -> Void)?

  public init (willCancel: ((AdvancedOperation, Error?) -> Void)? = nil) {
    self.willCancelHandler = willCancel
  }

  // MARK: - OperationObserving

  public func operationWillCancel(operation: AdvancedOperation, withError error: Error?) {
    willCancelHandler?(operation, error)
  }
}

internal final class DidCancelObserver: OperationDidCancelObserving {
  // MARK: - Properties

  private let didCancelHandler: ((AdvancedOperation, Error?) -> Void)?

  public init (didCancelHandler: ((AdvancedOperation, Error?) -> Void)? = nil) {
    self.didCancelHandler = didCancelHandler
  }

  // MARK: - OperationObserving

  public func operationDidCancel(operation: AdvancedOperation, withError error: Error?) {
    didCancelHandler?(operation, error)
  }
}

internal final class WillFinishObserver: OperationWillFinishObserving {
  // MARK: - Properties

  private let willFinishHandler: ((AdvancedOperation, Error?) -> Void)?

  public init (willFinishHandler: ((AdvancedOperation, Error?) -> Void)? = nil) {
    self.willFinishHandler = willFinishHandler
  }

  // MARK: - OperationObserving

  func operationWillFinish(operation: AdvancedOperation, withError error: Error?) {
    willFinishHandler?(operation, error)
  }
}
