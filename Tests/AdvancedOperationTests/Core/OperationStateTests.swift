// AdvancedOperation

import XCTest
@testable import AdvancedOperation

final class OperationStateTests: XCTestCase {
  func testTransition() {
    // ready
    XCTAssertTrue(AsyncOperation.State.ready.canTransition(to: .executing))
    XCTAssertTrue(AsyncOperation.State.ready.canTransition(to: .finished))
    XCTAssertFalse(AsyncOperation.State.ready.canTransition(to: .ready))

    // Executing
    XCTAssertFalse(AsyncOperation.State.executing.canTransition(to: .executing))
    XCTAssertTrue(AsyncOperation.State.executing.canTransition(to: .finished))
    XCTAssertFalse(AsyncOperation.State.executing.canTransition(to: .ready))

    // finished
    XCTAssertFalse(AsyncOperation.State.finished.canTransition(to: .executing))
    XCTAssertFalse(AsyncOperation.State.finished.canTransition(to: .finished))
    XCTAssertFalse(AsyncOperation.State.finished.canTransition(to: .ready))
  }

  func testDebugDescription() {
    XCTAssertEqual(AsyncOperation.State.ready.debugDescription.lowercased(), "ready")
    XCTAssertEqual(AsyncOperation.State.executing.debugDescription.lowercased(), "executing")
    XCTAssertEqual(AsyncOperation.State.finished.debugDescription.lowercased(), "finished")
  }
}
