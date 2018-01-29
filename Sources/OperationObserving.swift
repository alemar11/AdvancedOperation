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

/// The protocol that types may implement if they wish to be notified of significant operation lifecycle events.
public protocol OperationObserving {
  /// An unique identifier
  var identifier: String { get set }

  /// Invoked immediately prior to the `Operation`'s `main()` method (it's started but not yet executed).
  func operationDidStart(operation: Operation)

  /// Invoked as an `Operation` finishes, along with any errors produced during execution.
  /// - Note: An operation can finish without starting (i.e. if cancelled before its execution)
  func operationDidFinish(operation: Operation, withErrors errors: [Error])

  /// Invoked as an `Operation` is cancelled, along with any errors produced during execution.
  func operationDidCancel(operation: Operation, withErrors errors: [Error])
}
