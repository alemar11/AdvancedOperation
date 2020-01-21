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

open class AdvancedOperation: Operation {
  // MARK: - Public Properties
  
  /// An `OSLog` instance to log additional informations during the operation execution.
  ///
  /// - Note: To enable log add this environment key: `org.tinrobots.AdvancedOperation.LOG_ENABLED`
  public final var log: OSLog { return Log.`default` }
  
  // MARK: - Internal Properties
  
  // An identifier you use to distinguish signposts that have the same name and that log to the same OSLog.
  @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
  lazy var signpostID = {
    return OSSignpostID(log: Log.signpost, object: self)
  }()
  
  // MARK: - Private Properties
  
  private lazy var tracker: Tracker = {
    return Tracker(operation: self)
  }()
  
  public override init() {
    super.init()
    _ = tracker
  }
}
