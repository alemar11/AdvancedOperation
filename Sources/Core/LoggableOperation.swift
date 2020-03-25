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

/// Operations conforming to this protcol can log their most relevant status changes.
/// - Warning: If using Swift 5.0 or lower run `KVOCrashWorkaround.installFix()` to solve some  multithreading bugs in Swift's KVO.
public protocol LoggableOperation: Operation { }

private var loggerKey: UInt8 = 0
extension LoggableOperation {
  private var logger: Logger? {
    get {
      return objc_getAssociatedObject(self, &loggerKey) as? Logger
    }
    set {
      objc_setAssociatedObject(self, &loggerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Installs a logger into the `Operation`.
  /// - Parameters:
  ///   - log: `OSLog` instance for general purpose logging; this log can be accessed using the var `log`.
  ///   - signpost: `OSLog` instance to track when an Operation starts and ends.
  ///   - poi: `OSLog` instance to track point of interests (i.e. cancellation).
  public func installLogger() {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    // https://github.com/ReactiveX/RxSwift/blob/6b2a406b928cc7970874dcaed0ab18e7265e41ef/RxCocoa/Foundation/NSObject%2BRx.swift

    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The logger should be installed before any relevant operation phases are occurred.")
    if logger == nil {
      logger = Logger()
      logger?.start(operation: self)
    }
  }

  public func uninstallLogger() {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The logger should be uninstalled before any relevant operation phases are occurred.")

    logger = nil
  }
}

// MARK: - Logger

final class Logger {
  private static let signPostName: StaticString = "Operation execution"
  private let log = OSLog(subsystem: identifier, category: "General")
  private let signpost = OSLog(subsystem: identifier, category: "Signposts") // https://forums.developer.apple.com/thread/128736
  private lazy var poi: OSLog = {
    if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
      return OSLog(subsystem: identifier, category: OSLog.Category.pointsOfInterest)
    } else {
      return .disabled
    }
  }()

  private var started: Bool = false
  private var cancelled: Bool = false
  private var finished: Bool = false
  private var tokens = [NSKeyValueObservation]()

  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  fileprivate lazy var signpostID = {
    return OSSignpostID(log: signpost, object: self)
  }()

  // swiftlint:disable:next cyclomatic_complexity
  func start<T>(operation: T) where T: LoggableOperation {
    let lock = UnfairLock()

    let cancelToken = operation.observe(\.isCancelled, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }

      assert(!self.cancelled)

      self.cancelled = true

      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        os_log(.info, log: self.log, "%{public}s has been cancelled.", operation.operationName)
        if self.started {
          os_signpost(.event, log: self.poi, name: "Operation cancellation", signpostID: self.signpostID, "%{public}s has been cancelled.", operation.operationName)
        }
      } else {
        os_log("%{public}s has been cancelled.", log: self.log, type: .info, operation.operationName)
      }
    }

    let executionToken = operation.observe(\.isExecuting, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }

      if newValue {
        assert(!self.started)
        self.started = true
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_log(.info, log: self.log, "%{public}s has started.", operation.operationName)
          os_signpost(.begin, log: self.signpost, name: Logger.signPostName, signpostID: self.signpostID, "%{public}s has started.", operation.operationName)
        } else {
          os_log("%{public}s has started.", log: self.log, type: .info, operation.operationName)
        }
      }
    }

    let finishToken = operation.observe(\.isFinished, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      guard newValue else { return }

      assert(!self.finished)

      self.finished = true

      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        if let failableOperation = operation as? _FailableOperation, failableOperation.isFailed {
          os_log(.info, log: self.log, "%{public}s has finished with an error.", operation.operationName)
        } else {
          os_log(.info, log: self.log, "%{public}s has finished.", operation.operationName)
        }
      } else {
        if let failableOperation = operation as? _FailableOperation, failableOperation.isFailed {
          os_log("%{public}s has finished with an error.", log: self.log, type: .info, operation.operationName)
        } else {
          os_log("%{public}s has finished.", log: self.log, type: .info, operation.operationName)
        }
      }

      if self.started { // the end signpost should be logged only if the operation has logged the begin signpost
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_signpost(.end, log: self.signpost, name: Logger.signPostName, signpostID: self.signpostID, "%{public}s has finished.", operation.operationName)
        }
      }
    }

    tokens = [cancelToken, executionToken, finishToken]
  }

  deinit {
    tokens.forEach { $0.invalidate() }
    tokens = []
  }
}
