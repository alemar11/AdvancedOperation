//
// AdvancedOperation
//
// Copyright © 2016-2018 Tinrobots.
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

#if canImport(UIApplication)

import UIApplication

public protocol UIApplicationBackgroundTask {
  var applicationState: UIApplication.State { get }
  // var backgroundTimeRemaining: TimeInterval { get }
  func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: UIApplicationBackgroundTask { }

private extension Selector {
  static let didBecomeActive = #selector(UIBackgroundObserver.didBecomeActive(notification:))
  static let didEnterBackground = #selector(UIBackgroundObserver.didEnterBackground(notification:))
}

public final class UIBackgroundObserver: NSObject {

  public let backgroundTaskName = "\(identifier).UIBackgroundObserver.\(UUID().uuidString)"

  private let application: UIApplicationBackgroundTask
  private var taskIdentifier: UIBackgroundTaskIdentifier = .invalid

  public init(application: UIApplicationBackgroundTask) {
    self.application = application
    super.init()

    NotificationCenter.default.addObserver(self, selector: Selector.didEnterBackground, name: UIApplication.didEnterBackgroundNotification, object: .none)
    NotificationCenter.default.addObserver(self, selector: Selector.didBecomeActive, name: UIApplication.didBecomeActiveNotification, object: .none)

    if isInBackground {
      startBackgroundTask()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private var isInBackground: Bool {
    return application.applicationState == .background
  }

  /// The task is already running in background
  private var isActive: Bool {
    return taskIdentifier != .invalid
  }

  @objc
  fileprivate func didEnterBackground(notification: NSNotification) {
    if isInBackground {
      startBackgroundTask()
    }
  }

  @objc
  fileprivate func didBecomeActive(notification: NSNotification) {
    if !isInBackground {
      endBackgroundTask()
    }
  }

  private func startBackgroundTask() {
    if !isActive {
      taskIdentifier = application.beginBackgroundTask(withName: backgroundTaskName) {
        self.endBackgroundTask()
      }
    }
  }

  private func endBackgroundTask() {
    if isActive {
      application.endBackgroundTask(taskIdentifier)
      taskIdentifier = .invalid
    }
  }

}

extension UIBackgroundObserver: OperationDidFinishObserving {

  public func operationDidFinish(operation: Operation, withErrors errors: [Error]) {
    endBackgroundTask()
  }

}

#endif
