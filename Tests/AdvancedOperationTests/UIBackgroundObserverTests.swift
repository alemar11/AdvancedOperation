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

#if canImport(UIKit) && !os(watchOS)

import XCTest
@testable import AdvancedOperation

final class MockUIApplication: UIApplicationBackgroundTask {

  typealias DidBeginBackgroundTask = (_ name: String?, _ identifier: UIBackgroundTaskIdentifier) -> Void
  typealias DidEndBackgroundTask = (_ identifier: UIBackgroundTaskIdentifier) -> Void

  var testableApplicationState: UIApplication.State
  var didBeginBackgroundTask: DidBeginBackgroundTask?
  var didEndBackgroundTask: DidEndBackgroundTask?

  init(state: UIApplication.State, didBeginTask: DidBeginBackgroundTask? = .none, didEndTask: DidEndBackgroundTask? = .none) {
    testableApplicationState = state
    didBeginBackgroundTask = didBeginTask
    didEndBackgroundTask = didEndTask
  }

  var applicationState: UIApplication.State {
    return testableApplicationState //?? application.applicationState
  }

  func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
    let identifier = UIBackgroundTaskIdentifier.init(rawValue: 100)
    didBeginBackgroundTask?(taskName, identifier)
    return identifier
  }

  func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
    didEndBackgroundTask?(identifier)
  }

}

final class UIBackgroundObserverTests: XCTestCase {

  func applicationEntersBackground(application: MockUIApplication) {
    application.testableApplicationState = UIApplication.State.background
    NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self)
  }

  func applicationBecomesActive(application: MockUIApplication) {
    application.testableApplicationState = UIApplication.State.active
    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: self)
  }

  func testUIBackgroundObserverStartsBackgroundTask() {
    // Given
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

    let didBeginTask: MockUIApplication.DidBeginBackgroundTask = { name, identifier in
      backgroundTaskIdentifier = identifier
    }

    let didEndTask: MockUIApplication.DidEndBackgroundTask = { identifier in
      endedBackgroundTaskIdentifier = identifier
    }

    // When
    let application = MockUIApplication(state: .active, didBeginTask: didBeginTask, didEndTask: didEndTask)
    let observer = UIBackgroundObserver(application: application)
    let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
    operation.addObserver(observer)
    let expectation = self.expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock {
      expectation.fulfill()
    }

    // Then
    operation.start()
    applicationEntersBackground(application: application)
    waitForExpectations(timeout: 10, handler: nil)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    XCTAssertTrue(observer.backgroundTaskName.starts(with: "\(identifier).UIBackgroundObserver."))
    XCTAssertEqual(observer.taskIdentifier, .invalid)
  }

  func testUIBackgroundObserverStartsInBackgroundThenBecomesActive() {
    // Given
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

    let didBeginTask: MockUIApplication.DidBeginBackgroundTask = { (name, identifier) in
      backgroundTaskIdentifier = identifier
    }

    let didEndTask: MockUIApplication.DidEndBackgroundTask = { identifier in
      endedBackgroundTaskIdentifier = identifier
    }

    // When
    let application = MockUIApplication(state: .active, didBeginTask: didBeginTask, didEndTask: didEndTask)
    applicationEntersBackground(application: application)

    let observer = UIBackgroundObserver(application: application)
    let operation = SleepyAsyncOperation(interval1: 2, interval2: 2, interval3: 2)
    operation.addObserver(observer)
    let expectation = self.expectation(description: "\(#function)\(#line)")
    operation.addCompletionBlock {
      expectation.fulfill()
    }

    // Then
    operation.start()
    applicationBecomesActive(application: application)
    waitForExpectations(timeout: 10, handler: nil)

    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)
    XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    XCTAssertTrue(observer.backgroundTaskName.starts(with: "\(identifier).UIBackgroundObserver."))
    XCTAssertEqual(observer.taskIdentifier, .invalid)
  }

}

#endif
