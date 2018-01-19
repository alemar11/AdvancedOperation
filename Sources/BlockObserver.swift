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
  private let willPerform: ((Operation) -> Void)?
  private let didPerform: ((Operation, [Error]) -> Void)?
  private let willCancel: ((Operation, [Error]) -> Void)?
  private let didCancel: ((Operation, [Error]) -> Void)?

  init(willPerform: ((Operation) -> Void)? = nil,
       willCancel: ((Operation, [Error]) -> Void)? = nil,
       didCancel: ((Operation, [Error]) -> Void)? = nil,
       didPerform: ((Operation, [Error]) -> Void)?) {
    self.willPerform = willPerform
    self.didPerform = didPerform
    self.willCancel = willCancel
    self.didCancel = didCancel
  }

  // MARK: - OperationObserving

  func operationWillPerform(operation: Operation) {
    willPerform?(operation)
  }

  func operationDidPerform(operation: Operation, withErrors errors: [Error]) {
    didPerform?(operation, errors)
  }

  func operationWillCancel(operation: Operation, withErrors errors: [Error]) {
    willCancel?(operation, errors)
  }

  func operationDidCancel(operation: Operation, withErrors errors: [Error]) {
    didCancel?(operation, errors)
  }

}
