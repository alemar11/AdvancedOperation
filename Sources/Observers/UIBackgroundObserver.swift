//
// AdvancedOperation
//
// Copyright © 2016-2019 Tinrobots.
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

// TODO: https://developer.apple.com/documentation/foundation/processinfo/1617030-performexpiringactivity
// TODO: add a way to decide if the operation should continue in background when it's already running or not
// maybe we don't want to keep our app active if the operation hasn't started yet.

#if canImport(UIKit) && !os(watchOS)

import UIKit

public protocol UIApplicationBackgroundTask {
  var applicationState: UIApplication.State { get }
  func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: UIApplicationBackgroundTask { }

private extension Selector {
  static let didBecomeActive = #selector(UIBackgroundObserver.didBecomeActive(notification:))
  static let didEnterBackground = #selector(UIBackgroundObserver.didEnterBackground(notification:))
}

/// An `UIBackgroundObserver` instance lets an `AdvancedOperation` run for a period of time after the app transitions to the background.
public final class UIBackgroundObserver: NSObject {

  /// The task name.
  public let backgroundTaskName = "\(identifier).UIBackgroundObserver.\(UUID().uuidString)"

  /// A unique token that identifies a request to run in the background.
  public private(set) var taskIdentifier: UIBackgroundTaskIdentifier = .invalid

  private let application: UIApplicationBackgroundTask

  private var isExecuting: Bool = false

  /// Initializes a new `UIBackgroundObserver` instance.
  public init(application: UIApplicationBackgroundTask) {
    self.application = application
    super.init()

    NotificationCenter.default.addObserver(self, selector: Selector.didEnterBackground, name: UIApplication.didEnterBackgroundNotification, object: .none)
    NotificationCenter.default.addObserver(self, selector: Selector.didBecomeActive, name: UIApplication.didBecomeActiveNotification, object: .none)

    if application.applicationState == .background {
      startBackgroundTask()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc
  fileprivate func didEnterBackground(notification: NSNotification) {
    if application.applicationState == .background {
      startBackgroundTask()
    }
  }

  @objc
  fileprivate func didBecomeActive(notification: NSNotification) {
    if application.applicationState != .background {
      endBackgroundTask()
    }
  }

  private func startBackgroundTask() {
    if taskIdentifier == .invalid {
      taskIdentifier = application.beginBackgroundTask(withName: backgroundTaskName) {
        self.endBackgroundTask()
      }
    }
  }

  private func endBackgroundTask() {
    if taskIdentifier != .invalid {
      application.endBackgroundTask(taskIdentifier)
      taskIdentifier = .invalid
    }
  }

}

extension UIBackgroundObserver: OperationWillExecuteObserving & OperationDidFinishObserving {

  public func operationWillExecute(operation: AdvancedOperation) {
    isExecuting = true
  }

  public func operationDidFinish(operation: AdvancedOperation, withErrors errors: [Error]) {
    isExecuting = false
    endBackgroundTask()
  }

}

extension AdvancedOperation {

  ///  The operation continues to run, *for a period of time*, after the app transitions to the background.
  ///
  /// - Parameter application: An app instance conforming to `UIApplicationBackgroundTask`.
  /// - Returns: The `UIBackgroundObserver` added to the operation.
  /// - Note: The period of time is undefined.
  @discardableResult
  public func continueToRunInBackground(application: UIApplicationBackgroundTask) -> UIBackgroundObserver {
    let backgroundObserver = observers.read { $0.first { $0 is UIBackgroundObserver } }

    if let observer = backgroundObserver as? UIBackgroundObserver {
      return observer
    } else {
      let observer = UIBackgroundObserver(application: application)
      self.addObserver(observer)
      return observer
    }
  }

}

#endif
