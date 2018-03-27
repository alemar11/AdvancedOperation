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

import XCTest
@testable import AdvancedOperation

final class OperationStateTests: XCTestCase {

  func testTransition() {
    // Ready
    XCTAssertTrue(AdvancedOperation.OperationState.ready.canTransition(to: .executing))
    XCTAssertTrue(AdvancedOperation.OperationState.ready.canTransition(to: .pending))
    XCTAssertTrue(AdvancedOperation.OperationState.ready.canTransition(to: .finishing))
    XCTAssertFalse(AdvancedOperation.OperationState.ready.canTransition(to: .evaluating))
    XCTAssertFalse(AdvancedOperation.OperationState.ready.canTransition(to: .finished))
    XCTAssertFalse(AdvancedOperation.OperationState.ready.canTransition(to: .ready))

    // Pending
    XCTAssertTrue(AdvancedOperation.OperationState.pending.canTransition(to: .evaluating))
    XCTAssertFalse(AdvancedOperation.OperationState.pending.canTransition(to: .ready))
    XCTAssertFalse(AdvancedOperation.OperationState.pending.canTransition(to: .finished))
    XCTAssertFalse(AdvancedOperation.OperationState.pending.canTransition(to: .executing))
    XCTAssertFalse(AdvancedOperation.OperationState.pending.canTransition(to: .finishing))
    XCTAssertFalse(AdvancedOperation.OperationState.pending.canTransition(to: .pending))

    // Evaluating
    XCTAssertTrue(AdvancedOperation.OperationState.evaluating.canTransition(to: .ready))
    XCTAssertFalse(AdvancedOperation.OperationState.evaluating.canTransition(to: .executing))
    XCTAssertFalse(AdvancedOperation.OperationState.evaluating.canTransition(to: .finished))
    XCTAssertFalse(AdvancedOperation.OperationState.evaluating.canTransition(to: .evaluating))
    XCTAssertFalse(AdvancedOperation.OperationState.evaluating.canTransition(to: .finishing))
    XCTAssertFalse(AdvancedOperation.OperationState.evaluating.canTransition(to: .pending))

    // Executing
    XCTAssertTrue(AdvancedOperation.OperationState.executing.canTransition(to: .finishing))
    XCTAssertFalse(AdvancedOperation.OperationState.executing.canTransition(to: .executing))
    XCTAssertFalse(AdvancedOperation.OperationState.executing.canTransition(to: .finished))
    XCTAssertFalse(AdvancedOperation.OperationState.executing.canTransition(to: .evaluating))
    XCTAssertFalse(AdvancedOperation.OperationState.executing.canTransition(to: .ready))
    XCTAssertFalse(AdvancedOperation.OperationState.executing.canTransition(to: .pending))

    // Finishing
    XCTAssertTrue(AdvancedOperation.OperationState.finishing.canTransition(to: .finished))
    XCTAssertFalse(AdvancedOperation.OperationState.finishing.canTransition(to: .executing))
    XCTAssertFalse(AdvancedOperation.OperationState.finishing.canTransition(to: .evaluating))
    XCTAssertFalse(AdvancedOperation.OperationState.finishing.canTransition(to: .ready))
    XCTAssertFalse(AdvancedOperation.OperationState.finishing.canTransition(to: .pending))
    XCTAssertFalse(AdvancedOperation.OperationState.finishing.canTransition(to: .finishing))
  }

  func testDebugDescription() {
    XCTAssertEqual(AdvancedOperation.OperationState.ready.debugDescription.lowercased(), "ready")
    XCTAssertEqual(AdvancedOperation.OperationState.pending.debugDescription.lowercased(), "pending")
    XCTAssertEqual(AdvancedOperation.OperationState.evaluating.debugDescription.lowercased(), "evaluating conditions")
    XCTAssertEqual(AdvancedOperation.OperationState.executing.debugDescription.lowercased(), "executing")
    XCTAssertEqual(AdvancedOperation.OperationState.finishing.debugDescription.lowercased(), "finishing")
    XCTAssertEqual(AdvancedOperation.OperationState.finished.debugDescription.lowercased(), "finished")
  }

}
