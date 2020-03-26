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

// MARK: - MonitorableOperation

/// Operations conforming to this protcol have a `Monitorable` instance listening to their most relevant status changes.
/// - Warning: If using Swift 5.0 or lower run `KVOCrashWorkaround.installFix()` to solve some  multithreading bugs in Swift's KVO.
public protocol MonitorableOperation: Operation { }

private var monitorKey: UInt8 = 117
extension MonitorableOperation {
  /// `Monitorable` instance listening to the operation  most relevant status changes.
  var monitor: Monitor<Self> {
    return prepareMonitor()
  }

  private func prepareMonitor() -> Monitor<Self> {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The monitor should be used before any relevant operation phases are occurred.")

    if let monitor = _monitor {
      return monitor
    } else {
      _monitor = Monitor(operation: self)
      return _monitor!
    }
  }

  private var _monitor: Monitor<Self>? {
    get {
      return objc_getAssociatedObject(self, &monitorKey) as? Monitor
    }
    set {
      objc_setAssociatedObject(self, &monitorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

// MARK: - OperationMonitoring

/// Types conforming to this protocol can listes to the most relevant `Operation` status changes.
public protocol OperationMonitoring {
  // swiftlint:disable:next type_name
  associatedtype T: Operation
  // Adds a block to be called when the monitored `Operation` gets cancelled.
  func addCancelBlock(_ block: @escaping (T) -> Void)
  // Adds a block to be called when the monitored `Operation` starts executing its main task.
  func addStartExecutionBlock(_ block: @escaping  (T) -> Void)
  // Adds a block to be called when the monitored `Operation` finishes executing its main task.
  func addFinishBlock(_ block: @escaping  (T) -> Void)
}

// MARK: - KVO OperationMonitoring implementation

/// Monitors an `Operation` most relevant status changes via KVO.
public final class Monitor<T: MonitorableOperation>: OperationMonitoring {
  public typealias Block = (T) -> Void
  private weak var operation: T?
  private let lock = UnfairLock()
  private var cancelBlocks = [Block]()
  private var startExecutionBlocks = [Block]()
  private var finishBlocks = [Block]()
  private var tokens = [NSKeyValueObservation]()

  public init(operation: T) {
    self.operation = operation
    setup()
  }

  deinit {
    tokens.forEach { $0.invalidate() }
    tokens = []
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func setup() {
    let lock = UnfairLock()

    let cancelToken = operation?.observe(\.isCancelled, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard self.operation === operation else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }

      self.cancelBlocks.forEach { $0(operation) }
    }

    let executionToken = operation?.observe(\.isExecuting, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard self.operation === operation else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      guard newValue else { return }

      self.startExecutionBlocks.forEach { $0(operation) }
    }

    let finishToken = operation?.observe(\.isFinished, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard self.operation === operation else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      guard newValue else { return }

      self.finishBlocks.forEach { $0(operation) }
    }

    tokens = [cancelToken, executionToken, finishToken].compactMap { $0 }
  }

  // Adds a block to be called when the monitored `Operation` gets cancelled.
  public func addCancelBlock(_ block: @escaping Block) {
    lock.lock()
    defer { lock.unlock() }
    cancelBlocks.append(block)
  }

  // Adds a block to be called when the monitored `Operation` starts executing its main task.
  public func addStartExecutionBlock(_ block: @escaping Block) {
    lock.lock()
    defer { lock.unlock() }
    startExecutionBlocks.append(block)
  }

  // Adds a block to be called when the monitored `Operation` finishes executing its main task.
  public func addFinishBlock(_ block: @escaping Block) {
    lock.lock()
    defer { lock.unlock() }
    finishBlocks.append(block)
  }
}
