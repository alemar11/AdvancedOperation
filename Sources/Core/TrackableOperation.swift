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
/// To enable logging:
/// - To enable log add this environment key: `org.tinrobots.AdvancedOperation.LOG_ENABLED`
/// - To enable signposts add this environment key: `org.tinrobots.AdvancedOperation.SIGNPOST_ENABLED`
/// - To enable point of interests add this environment key: `org.tinrobots.AdvancedOperation.POI_ENABLED`
/// - Warning: If using Swift 5.0  run `KVOCrashWorkaround.installFix()` to solve some  multithreading bugs in Swift's KVO.
protocol TrackableOperation: Operation {
  var log: OSLog { get }
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  var poi: OSLog { get }
}

extension TrackableOperation {
  var log: OSLog { return Log.`default` }
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  var poi: OSLog { return Log.poi }
}

private var trackerKey: UInt8 = 0
extension TrackableOperation {
  private(set) var tracker: Tracker? {
    get {
      return objc_getAssociatedObject(self, &trackerKey) as? Tracker
    }
    set {
      objc_setAssociatedObject(self, &trackerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public func installTracker() {
    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The tracker should be installed before any relevation operation phases are occurred.")
    if tracker == nil {
      tracker = Tracker(operation: self)
    }
  }
}

// MARK: - Tracker

final class Tracker {
  private var tokens = [NSKeyValueObservation]()
  private var started: Bool = false
  private var cancelled: Bool = false
  private var finished: Bool = false
  
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  lazy var signpostID = {
    return OSSignpostID(log: Log.signpost, object: self)
  }()
  
  init<T>(operation: T) where T: TrackableOperation {
    // uses default and poi logs
    let cancelToken = operation.observe(\.isCancelled, options: [.old, .new]) { [weak self] (operation, changes) in
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      
      assert(!self.cancelled)
      
      self.cancelled = true
      
      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        os_log(.info, log: Log.`default`, "%{public}s has been cancelled.", operation.operationName)
      } else {
        os_log("%{public}s has been cancelled.", log: Log.`default`, type: .info, operation.operationName)
      }
      
      if self.started {
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_signpost(.event, log: Log.poi, name: "Cancellation", signpostID: self.signpostID, "⏺ %{public}s has been cancelled.", operation.operationName)
        }
      }
    }
    
    // uses default and signpost logs
    let executionToken = operation.observe(\.isExecuting, options: [.old, .new]) { [weak self] (operation, changes) in
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      
      if newValue {
        assert(!self.started)
        self.started = true
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_log(.info, log: Log.`default`, "%{public}s has started.", operation.operationName)
          os_signpost(.begin, log: Log.signpost, name: Log.signPostIntervalName, signpostID: self.signpostID, "🔼 %{public}s has started.", operation.operationName)
        } else {
          os_log("%{public}s has started.", log: operation.log, type: .info, operation.operationName)
        }
      }
    }
    
    // uses default and signpost logs
    let finishToken = operation.observe(\.isFinished, options: [.old, .new]) { [weak self] (operation, changes) in
      guard let self = self else { return }
      guard let oldValue = changes.oldValue, let newValue = changes.newValue, oldValue != newValue else { return }
      guard newValue else { return }
      
      assert(!self.finished)
      
      self.finished = true
      
      if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
        os_log(.info, log: Log.`default`, "%{public}s has finished.", operation.operationName)
      } else {
        os_log("%{public}s has finished.", log: Log.`default`, type: .info, operation.operationName)
      }
      
      if self.started { // the end signpost should be logged only if the operation has logged the begin signpost
        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
          os_signpost(.end, log: Log.signpost, name: Log.signPostIntervalName, signpostID: self.signpostID, "🔽 %{public}s has finished.", operation.operationName)
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

