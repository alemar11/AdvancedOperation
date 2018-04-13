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

class SilentConditionTests: XCTestCase {

  func testSilentCondition() {
    let queue = AdvancedOperationQueue()

    let expectation1 = expectation(description: "\(#function)\(#line)")
    let expectation2 = expectation(description: "\(#function)\(#line)")
    let expectation3 = expectation(description: "\(#function)\(#line)")
    let expectation4 = expectation(description: "\(#function)\(#line)")

    expectation4.isInverted = true

    let operation1 = SleepyOperation()
    operation1.completionBlock = { expectation1.fulfill() }

    let operation2 = SleepyOperation()
    operation2.completionBlock = { expectation2.fulfill() }

    let dependecy1 = AdvancedBlockOperation { }
    dependecy1.completionBlock = { expectation3.fulfill() }

    let dependecy2 = AdvancedBlockOperation { }
    dependecy2.completionBlock = { expectation4.fulfill() }

    let dependencyCondition1 = DependencyCondition(dependency: dependecy1)
    let dependencyCondition2 = DependencyCondition(dependency: dependecy2)

    operation1.addCondition(dependencyCondition1)
    operation2.addCondition(SilentCondition(condition: dependencyCondition2))

    queue.addOperations([operation1, operation2], waitUntilFinished: false)
    waitForExpectations(timeout: 10)
  }

}
