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

/// Types which conform to this protocol, can be attached to `AdvancedOperation` subclasses before they are executed or added to a queue.
public protocol OperationObservingType { }

public protocol OperationWillExecuteObserving: OperationObservingType {
  /// Invoked immediately prior to the `Operation`'s `main()` method (it's started but not yet executed).
  func operationWillExecute(operation: AdvancedOperation)
}

public protocol OperationWillFinishObserving: OperationObservingType {
  /// Invoked as an `Operation` finishes, along with any errors produced during execution.
  /// - Note: An operation can finish without starting (i.e. if cancelled before its execution)
  func operationWillFinish(operation: AdvancedOperation, withErrors errors: [Error])
}

public protocol OperationDidFinishObserving: OperationObservingType {
  /// Invoked as an `Operation` finishes, along with any errors produced during execution.
  /// - Note: An operation can finish without starting (i.e. if cancelled before its execution)
  /// - Warning: This method will be invoked **after** the operation `completionBlock`.
  func operationDidFinish(operation: AdvancedOperation, withErrors errors: [Error])
}

public protocol OperationWillCancelObserving: OperationObservingType {
  /// Invoked as an `Operation` is cancelled, along with any errors produced during execution.
  func operationWillCancel(operation: AdvancedOperation, withErrors errors: [Error])
}

public protocol OperationDidCancelObserving: OperationObservingType {
  /// Invoked as an `Operation` is cancelled, along with any errors produced during execution.
  func operationDidCancel(operation: AdvancedOperation, withErrors errors: [Error])
}

public protocol OperationDidProduceOperationObserving: OperationObservingType {
  /// Invoked as an `Operation` produces another `Operation` during execution.
  func operation(operation: AdvancedOperation, didProduce: Operation)
}

public protocol OperationDidFinishConditionsEvaluationsObserving: OperationObservingType {
  /// Invoked as an `Operation` has fineshed the evaluation of its conditions, along with any errors produced during the evaluation.
  func operationDidFailConditionsEvaluations(operation: AdvancedOperation, withErrors errors: [Error])
}

/// The protocol that types may implement if they wish to be notified of significant operation lifecycle events.
// swiftlint:disable:next line_length
public protocol OperationObserving: OperationWillExecuteObserving, OperationWillFinishObserving, OperationDidFinishObserving, OperationWillCancelObserving, OperationDidCancelObserving, OperationDidProduceOperationObserving, OperationDidFinishConditionsEvaluationsObserving { }

public extension OperationDidFinishConditionsEvaluationsObserving {
  func operationDidFailConditionsEvaluations(operation: AdvancedOperation, withErrors errors: [Error]) { }
}
