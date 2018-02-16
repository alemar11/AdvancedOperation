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

  private let willExecuteHandler: ((Operation) -> Void)?
  private let didFinishHandler: ((Operation, [Error]) -> Void)?
  private let didCancelHandler: ((Operation, [Error]) -> Void)?

  init(willExecute: ((Operation) -> Void)? = nil,
       didCancel: ((Operation, [Error]) -> Void)? = nil,
       didFinish: ((Operation, [Error]) -> Void)?) {
    self.willExecuteHandler = willExecute
    self.didFinishHandler = didFinish
    self.didCancelHandler = didCancel
  }

  // MARK: - OperationObserving

  func operationWillExecute(operation: Operation) {
    willExecuteHandler?(operation)
  }

  func operationDidFinish(operation: Operation, withErrors errors: [Error]) {
    didFinishHandler?(operation, errors)
  }

  func operationDidCancel(operation: Operation, withErrors errors: [Error]) {
    didCancelHandler?(operation, errors)
  }

}
