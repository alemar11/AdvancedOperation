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

internal let identifier = "org.tinrobots.AdvancedOperation"

//open class AdvancedOperation: Operation {
//  // MARK: - Public Properties
//  
//  /// An `OSLog` instance to log additional informations during the operation execution.
//  ///
//  /// - Note: To enable log add this environment key: `org.tinrobots.AdvancedOperation.LOG_ENABLED`
//  public final var log: OSLog { return Log.`default` }
//  
//  // MARK: - Internal Properties
//  
//  // An identifier you use to distinguish signposts that have the same name and that log to the same OSLog.
//  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
//  lazy var signpostID = {
//    return OSSignpostID(log: Log.signpost, object: self)
//  }()
//  
//  // MARK: - Private Properties
//  
//  private lazy var tracker: Tracker = {
//    return Tracker(operation: self)
//  }()
//  
//  // MARK: - Initializers
//  
//  public override init() {
//    super.init()
//    _ = tracker
//  }
//}

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
      if self.tracker == nil { // TODO we can move this check into the installTracker method
        objc_setAssociatedObject(self, &trackerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      } else {
        print("TODO: already installed")
      }
    }
  }
  
  func installTracker() {
    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The tracker should be installed before any relevation operation phases are occurred.")
    tracker = Tracker(operation: self)
  }
  
//  func uninstallTracker() {
//    precondition(!self.isExecuting || !self.isFinished || !self.isCancelled, "The tracker should be uninstalled before any relevation operation phases are occurred.")
//    self.tracker = nil
//  }
}


//struct Precondition {
//  private let block: (Operation) -> Bool
//  init(block: @escaping (Operation) -> Bool) {
//    self.block = block
//  }
//  
//  static let notCancelledDependencies = Precondition { !$0.hasSomeCancelledDependencies }
//  static let noFailedDependencies = Precondition { !$0.hasSomeFailedDependencies }
//}
//
//protocol PrecondiotionedOperation: Operation {
//  func addPreCondition(_ precondition: Precondition)
//  func evaluatePreconditions() -> Error?
//}
//
//extension PrecondiotionedOperation {
//  
//}

