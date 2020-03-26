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
public protocol StateObservableOperation: Operation { }

private var monitorKey: UInt8 = 117
extension StateObservableOperation {
  /// `StateObserver` instance listening to the operation state changes.
  /// - Warning: "The observer should be used before any relevant operation phases are occurred."
  var state: StateObserver<Self> {
    return prepareObserver()
  }

  private func prepareObserver() -> StateObserver<Self> {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    if let observer = _observer {
      return observer
    } else {
      _observer = StateObserver(operation: self)
      return _observer!
    }
  }

  private var _observer: StateObserver<Self>? {
    get {
      return objc_getAssociatedObject(self, &monitorKey) as? StateObserver
    }
    set {
      objc_setAssociatedObject(self, &monitorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

public final class StateObserver<T: StateObservableOperation> {
  public enum ObservedState {
    case ready
    case cancelled
    case executing
    case finished
  }

  private weak var operation: T?
  private let lock = UnfairLock()
  private var handlersByKey = [String: [(T) -> Void]]()
  private var tokensByKey = [String: NSKeyValueObservation]()

  internal init(operation: T) {
    self.operation = operation
  }

  deinit {
    tokensByKey.values.forEach { $0.invalidate() }
    tokensByKey = [:]
  }

  /// Observes changes for a given state.
  ///
  /// - Parameters:
  ///   - state: The `Operation` state to observe.
  ///   - handler: The block to be executed once the observed `Operation` state changes.
  public func observe(_ state: ObservedState, handler: @escaping (T) -> Void) {
    lock.lock()
    defer { lock.unlock() }

    let keyPath: KeyPath<T, Bool>
    switch state {
    case .ready:
      keyPath = \.isReady
    case .cancelled:
      keyPath = \.isCancelled
    case .executing:
      keyPath = \.isExecuting
    case.finished:
      keyPath = \.isFinished
    }

    guard let key = keyPath._kvcKeyPathString else { return }

    // Creates a NSKeyValueObservation for the observed keyPath if it's not already there.
    if !tokensByKey.keys.contains(key) {
      let token = operation?.observe(keyPath, options: [.old, .new]) { [weak self] (operation, changes) in
        guard let self = self else { return }
        guard self.operation === operation else { return }
        guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return } // only real changes are evaluated

        self.handlersByKey[key]?.forEach { $0(operation) }
      }
      tokensByKey[key] = token
    }

    // Stores the handler
    if var handlers = handlersByKey[key] {
      handlers.append(handler)
      handlersByKey[key] = handlers
    } else {
      handlersByKey[key] = [handler]
    }
  }
}
