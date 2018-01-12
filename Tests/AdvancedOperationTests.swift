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

class AdvancedOperationTests: XCTestCase {

  private class SleepyAsyncOperation: AdvancedOperation {

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

  private class SleepyOperation: AdvancedOperation {
    enum Error: Swift.Error { case test }
    
    override func main() {
      sleep(1)
      self.finish(errors: [Error.test])
    }
  }

  func testStart() {
    let exp = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    wait(for: [exp], timeout: 10)
    XCTAssertEqual(operation.errors.count, 0)
    XCTAssertFalse(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)

  }

  func testCancel() {
    let exp = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    sleep(3)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)

    wait(for: [exp], timeout: 10)
    XCTAssertEqual(operation.errors.count, 0)
    //waitForExpectations(timeout: 10, handler: nil)
  }

  func testBailingOutEarly() {
    //let exp = expectation(description: "\(#function)\(#line)")
    
    let operation = SleepyAsyncOperation()
    operation.completionBlock = {
      //exp.fulfill()
    }

    XCTAssertTrue(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.cancel()

    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertFalse(operation.isExecuting)
    XCTAssertTrue(operation.isCancelled)
    XCTAssertTrue(operation.isFinished)

    operation.cancel()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    sleep(3)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)

    operation.waitUntilFinished()
    XCTAssertEqual(operation.errors.count, 0)
    //wait(for: [exp], timeout: 10)
    //waitForExpectations(timeout: 10, handler: nil)
  }

  func testObservers() {

    class Observer: OperationObserving {

      var didStartCount = 0
      var didFinishCount = 0

      func operationDidStart(operation: AdvancedOperation) {
        didStartCount += 1
      }

      func operationDidFinish(operation: AdvancedOperation, errors: [Error]) {
        didFinishCount += 1
      }

    }

    let exp = expectation(description: "\(#function)\(#line)")
    let observer = Observer()
    let operation = SleepyAsyncOperation()
    operation.addObserver(observer: observer)

    operation.completionBlock = { exp.fulfill() }

    operation.start()

    wait(for: [exp], timeout: 10)
    XCTAssertEqual(observer.didStartCount, 1)
    XCTAssertEqual(observer.didFinishCount, 1)
    XCTAssertEqual(operation.errors.count, 0)
  }

  func testCancelWithErrors() {
    let exp = expectation(description: "\(#function)\(#line)")

    let operation = SleepyAsyncOperation()
    operation.completionBlock = { exp.fulfill() }
    operation.start()
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isExecuting)
    XCTAssertFalse(operation.isCancelled)
    XCTAssertFalse(operation.isFinished)

    operation.cancel(error: SleepyOperation.Error.test)
    XCTAssertFalse(operation.isReady)
    XCTAssertTrue(operation.isCancelled)
    sleep(3)
    XCTAssertTrue(operation.isFinished)
    XCTAssertFalse(operation.isExecuting)


    wait(for: [exp], timeout: 10)
    XCTAssertEqual(operation.errors.count, 1)
  }

  func testFinishWithErrors() {
    let operation = SleepyOperation()
    operation.start()
    XCTAssertEqual(operation.errors.count, 1)
  }

}
