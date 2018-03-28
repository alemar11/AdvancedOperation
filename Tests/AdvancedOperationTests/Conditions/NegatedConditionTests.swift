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

class NegatedConditionTests: XCTestCase {
    
  func testIsMutuallyExclusive() {
    XCTAssertFalse(NegatedCondition(condition: NoFailedDependenciesCondition()).isMutuallyExclusive)
  }

  func testName() {
    let conditionName = NoFailedDependenciesCondition().name
    XCTAssertEqual(NegatedCondition(condition: NoFailedDependenciesCondition()).name, "Not<\(conditionName)>")
  }

  func testNegationWithFailingCondition() {
    let negatedFailingCondition = NegatedCondition(condition: AlwaysFailingCondition())
    let dummyOperation = AdvancedBlockOperation { }
    let expectation1 = expectation(description: "\(#function)\(#line)")
    negatedFailingCondition.evaluate(for: dummyOperation) { (result) in
      switch result {
      case .satisfied: expectation1.fulfill()
      default: return
      }
    }
    waitForExpectations(timeout: 2)
  }

  func testNegationWithSuccessingCondition() {
    let negatedFailingCondition = NegatedCondition(condition: AlwaysSuccessingCondition())
    let dummyOperation = AdvancedBlockOperation { }
    let expectation1 = expectation(description: "\(#function)\(#line)")
    negatedFailingCondition.evaluate(for: dummyOperation) { (result) in
      switch result {
      case .failed(_): expectation1.fulfill()
      default: return
      }
    }
    waitForExpectations(timeout: 2)
  }
  
}
