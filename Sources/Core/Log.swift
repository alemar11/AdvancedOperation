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

// MARK: - Log

internal enum Log {
    /// The name used for signpost interval events (.begin and .end).
    static let signPostIntervalName: StaticString = "Operation"
    
    /// The `OSLog` instance used to track the operation changes (by default is disabled).
    static var `default`: OSLog {
        if ProcessInfo.processInfo.environment.keys.contains("\(identifier).LOG_ENABLED") {
            return OSLog(subsystem: identifier, category: "default")
        } else {
            return .disabled
        }
    }
    
    /// The `OSLog` instance used to track operation signposts (by default is disabled).
    @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
    static var signpost: OSLog {
        if ProcessInfo.processInfo.environment.keys.contains("\(identifier).SIGNPOST_ENABLED") {
            return OSLog(subsystem: identifier, category: "Signpost")
        } else {
            return .disabled
        }
    }
    
    /// The `OSLog` instance used to track operation point of interests (by default is disabled).
    @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
    static var poi: OSLog {
        if ProcessInfo.processInfo.environment.keys.contains("\(identifier).POI_ENABLED") {
            return OSLog(subsystem: identifier, category: .pointsOfInterest)
        } else {
            return .disabled
        }
    }
}
