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

class GroupOperationTests: XCTestCase {
  
  
  func testFlow() {
    
    class OperationOne: AdvancedOperation {
      override func main() {
        DispatchQueue.global().async { [weak weakSelf = self] in
          guard let strongSelf = weakSelf else { return self.finish() }
          
          if strongSelf.isCancelled { strongSelf.finish() }
          sleep(2)
          if strongSelf.isCancelled { strongSelf.finish() }
          sleep(3)
          strongSelf.finish()
        }
      }
    }
    
    let exp1 = expectation(description: "\(#function)\(#line)")
    let operationOne = OperationOne()
    operationOne.addCompletionBlock { exp1.fulfill() }
    
    let exp2 = expectation(description: "\(#function)\(#line)")
    let operationTwo =  BlockOperation(block: { sleep(1)})
    operationTwo.addCompletionBlock { exp2.fulfill() }
    
    let exp3 = expectation(description: "\(#function)\(#line)")
    let group = GroupOperation(operations: operationOne, operationTwo)
    group.addCompletionBlock { exp3.fulfill() }
    
    group.start()
    
    wait(for: [exp1, exp2, exp3], timeout: 10)
    XCTAssertFalse(group.isExecuting)
    XCTAssertFalse(group.isCancelled)
    XCTAssertTrue(group.isFinished)
    
  }
  
}
