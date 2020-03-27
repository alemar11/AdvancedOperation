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
//
// https://github.com/ReactiveX/RxSwift/blob/6b2a406b928cc7970874dcaed0ab18e7265e41ef/RxCocoa/Foundation/NSObject%2BRx.swift

import Foundation
import os.log

// MARK: - StateObservableOperation

/// Operations conforming to this protcol can easily observe to their most relevant status changes.
/// - Warning: If using Swift 5.0 or lower run `KVOCrashWorkaround.installFix()` to solve some  multithreading bugs in Swift's KVO.
public protocol ObservableOperation: Operation { }

private var observerKey: UInt8 = 117
extension ObservableOperation {
  /// `StateObserver` instance listening to the operation state changes.
  /// - Warning: "The observer should be used before any relevant operation phases are occurred."
  var kvo: KVOOperationObserver<Self> {
    return prepareObserver()
  }

  private func prepareObserver() -> KVOOperationObserver<Self> {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    if let observer = _observer {
      return observer
    } else {
      _observer = KVOOperationObserver(operation: self)
      return _observer!
    }
  }

  private var _observer: KVOOperationObserver<Self>? {
    get {
      return objc_getAssociatedObject(self, &observerKey) as? KVOOperationObserver
    }
    set {
      objc_setAssociatedObject(self, &observerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

public final class KVOOperationObserver<T: ObservableOperation> {
  private weak var operation: T?
  private let lock = UnfairLock()
  private var tokens = [NSKeyValueObservation]()

  internal init(operation: T) {
    self.operation = operation
  }

  deinit {
    tokens.forEach { $0.invalidate() }
    tokens = []
  }

  /// Observes changes for a  KVC compilant `Operation` property via its keyPath definition.
  ///
  /// - Parameters:
  ///   - keyPath: The Operation KVC compliant property to observe.
  ///   - options: Options to determine the values that are returned as part of the change dictionary. You can pass 0 if you require no change dictionary values.
  ///   - handler: The block called when the property changes.
  ///
  /// - Note: If you don't need to know how a property has changed, omit the options parameter.
  ///         Omitting the options parameter forgoes storing the new and old property values, which causes the oldValue and newValue properties to be nil.
  public func observe<Value>(_ keyPath: KeyPath<T, Value>, options: NSKeyValueObservingOptions, handler: @escaping (T, NSKeyValueObservedChange<Value>) -> Void) {
    lock.lock()
    defer { lock.unlock() }

    if let token = operation?.observe(keyPath, options: options, changeHandler: { handler($0, $1) }) {
      tokens.append(token)
    }
  }

  /// Observes changes for a  KVC compilant `Operation` property via its keyPath definition without needing to know how that property has changed.
  ///
  /// - Parameters:
  ///   - keyPath: The Operation KVC compliant property to observe.
  ///   - handler:  The block called when the property changes.
  public func observe<Value>(_ keyPath: KeyPath<T, Value>, handler: @escaping (T) -> Void) {
    lock.lock()
    defer { lock.unlock() }

    if let token = operation?.observe(keyPath, changeHandler: { operation, _ in handler(operation) }) {
      tokens.append(token)
    }
  }
}
