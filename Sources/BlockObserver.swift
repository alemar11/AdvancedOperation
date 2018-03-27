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

/// The `BlockObserver` is a way to attach arbitrary blocks to significant events in an `Operation`'s lifecycle.
struct BlockObserver: OperationObserving {

  // MARK: - Properties

  var identifier = UUID().uuidString

  private let willExecuteHandler: ((AdvancedOperation) -> Void)?
  private let willFinishHandler: ((AdvancedOperation, [Error]) -> Void)?
  private let didFinishHandler: ((AdvancedOperation, [Error]) -> Void)?
  private let willCancelHandler: ((AdvancedOperation, [Error]) -> Void)?
  private let didCancelHandler: ((AdvancedOperation, [Error]) -> Void)?

  init (
    willExecute: ((AdvancedOperation) -> Void)? = nil,
    willCancel: ((AdvancedOperation, [Error]) -> Void)? = nil,
    didCancel: ((AdvancedOperation, [Error]) -> Void)? = nil,
    willFinish: ((AdvancedOperation, [Error]) -> Void)? = nil,
    didFinish: ((AdvancedOperation, [Error]) -> Void)? = nil
    ) {
    self.willExecuteHandler = willExecute

    self.willFinishHandler = willFinish
    self.didFinishHandler = didFinish

    self.willCancelHandler = willCancel
    self.didCancelHandler = didCancel
  }

  // MARK: - OperationObserving

  // swiftlint:disable force_cast
  func operationWillExecute(operation: Operation) {
    willExecuteHandler?(operation as! AdvancedOperation)
  }

  func operationWillFinish(operation: Operation, withErrors errors: [Error]) {
    willFinishHandler?(operation as! AdvancedOperation, errors)
  }

  func operationDidFinish(operation: Operation, withErrors errors: [Error]) {
    didFinishHandler?(operation as! AdvancedOperation, errors)
  }

  func operationWillCancel(operation: Operation, withErrors errors: [Error]) {
    willCancelHandler?(operation as! AdvancedOperation, errors)
  }

  func operationDidCancel(operation: Operation, withErrors errors: [Error]) {
    didCancelHandler?(operation as! AdvancedOperation, errors)
  }

  // swiftlint:enable force_cast

}
