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
public protocol TrackableOperation: Operation { }

private var trackerKey: UInt8 = 0
extension TrackableOperation {
  private(set) var tracker: Tracker? {
    get {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }

      return objc_getAssociatedObject(self, &trackerKey) as? Tracker
    }
    set {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }

      objc_setAssociatedObject(self, &trackerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  public func installTracker(log: OSLog = .default, signpost: OSLog = .disabled, poi: OSLog = .disabled) {
    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The tracker should be installed before any relevant operation phases are occurred.")
    if tracker == nil {
      tracker = Tracker(log: log, signpost: signpost, poi: poi)
      tracker?.start(operation: self)
    }
  }

  // TODO: expose this log?
  internal var log: OSLog {
    return tracker?.log ?? .disabled
  }
}

// MARK: - Tracker

final class Tracker {
  static let signPostIntervalName: StaticString = "Operation"

  fileprivate let log: OSLog
  private let signpost: OSLog
  private let poi: OSLog
  private var started: Bool = false
  private var cancelled: Bool = false
  private var finished: Bool = false
  private var tokens = [NSKeyValueObservation]()

  init(log: OSLog, signpost: OSLog, poi: OSLog) {
    self.log = log
    self.signpost = signpost
    self.poi = poi
  }

  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  private lazy var signpostID = {
    return OSSignpostID(log: signpost, object: self)
  }()

  // swiftlint:disable:next cyclomatic_complexity
  func start<T>(operation: T) where T: TrackableOperation {
    let lock = UnfairLock()

    // uses default and poi logs
    let cancelToken = operation.observe(\.isCancelled, options: [.old, .new]) { [weak self] (operation, changes) in
      lock.lock()
      defer { lock.unlock() }
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }

      assert(!self.cancelled)

      self.cancelled = true

      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        os_log(.info, log: self.log, "%{public}s has been cancelled.", operation.operationName)
      } else {
        os_log("%{public}s has been cancelled.", log: self.log, type: .info, operation.operationName)
      }

      if self.started {
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_signpost(.event, log: self.poi, name: "Cancellation", signpostID: self.signpostID, "⏺ %{public}s has been cancelled.", operation.operationName)
        }
      }
    }

    // uses default and signpost logs
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
          os_signpost(.begin, log: self.signpost, name: Tracker.signPostIntervalName, signpostID: self.signpostID, "🔼 %{public}s has started.", operation.operationName)
        } else {
          os_log("%{public}s has started.", log: self.log, type: .info, operation.operationName)
        }
      }
    }

    // uses default and signpost logs
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
          os_signpost(.end, log: self.signpost, name: Tracker.signPostIntervalName, signpostID: self.signpostID, "🔽 %{public}s has finished.", operation.operationName)
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
