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

//import Foundation
//import os.log
//
//open class SynchronousOperation<OutputType>: Operation, OutputProducing {
//    public final override var isAsynchronous: Bool { return false }
//    public final override var isConcurrent: Bool { return false }
//    
//    /// The  output produced by the `AsynchronousOperation`.
//    /// It's always `nil` while the operation is not finished or if the operation gets cancelled before being executed.
//    public private(set) var output: OutputType? = nil
//    
//    // MARK: - Private Properties
//    
//    // An identifier you use to distinguish signposts that have the same name and that log to the same OSLog.
//    @available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *)
//    private lazy var signpostID = {
//        return OSSignpostID(log: Log.signpost, object: self)
//    }()
//    
//    public final override func start() {
//        guard !isFinished else { return }
//        
//        guard !isExecuting else { return }
//        
//        // The super.start() method is already able to disambiguate started operations (see notes below)
//        // but we need this to support os_log and os_signpost without having duplicates.
//        //        let isAlreadyRunning = isRunning.mutate { running -> Bool in
//        //            if running {
//        //                return true
//        //            } else {
//        //                // it will be considered as running from now on
//        //                running = true
//        //                return false
//        //            }
//        //        }
//        
//        //guard !isAlreadyRunning else { return }
//        
//        // early bailing out
//        if isCancelled {
//            if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//                os_log(.info, log: Log.general, "%{public}s has started after being cancelled.", operationName)
//                os_signpost(.begin, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has started.", operationName)
//            } else {
//                os_log("%{public}s has started after being cancelled.", log: Log.general, type: .info, operationName)
//            }
//            
//            finishLog()
//            return
//        }
//        
//        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//            os_log(.info, log: Log.general, "%{public}s has started.", operationName)
//            os_signpost(.begin, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has started.", operationName)
//        } else {
//            os_log("%{public}s has started.", log: Log.general, type: .info, operationName)
//        }
//        super.start()
//    }
//    
//    public final override func main() {
//        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//            os_signpost(.event, log: Log.poi, name: "Execution", signpostID: signpostID, "%{public}s is executing.", operationName)
//        }
//        
//        execute { [weak self] output in self?.output = output }
//        finishLog()
//        
//    }
//    
//    private func finishLog() {
//        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//            os_log(.info, log: Log.general, "%{public}s has finished.", operationName)
//            os_signpost(.end, log: Log.signpost, name: Log.signPostIntervalName, signpostID: signpostID, "%{public}s has finished.", operationName)
//        } else {
//            os_log("%{public}s has finished.", log: Log.general, type: .info, operationName)
//        }
//    }
//    
//    open override func cancel() {
//        guard !isCancelled else { return }
//        
//        super.cancel()
//        
//        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//            os_log(.info, log: Log.general, "%{public}s has been cancelled.", operationName)
//        } else {
//            os_log("%{public}s has been cancelled.", log: Log.general, type: .info, operationName)
//        }
//        
//        if #available(iOS 12.0, iOSApplicationExtension 12.0, tvOS 12.0, watchOS 5.0, macOS 10.14, OSXApplicationExtension 10.14, *) {
//            os_signpost(.event, log: Log.poi, name: "Cancellation", signpostID: signpostID, "%{public}s has been cancelled.", operationName)
//        }
//    }
//    
//    open func execute(completion: @escaping (Output) -> Void) {
//        preconditionFailure("Subclasses must implement `execute`.")
//    }
//}
