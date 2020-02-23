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

import XCTest
@testable import AdvancedOperation

final class LoopOperationTests: XCTestCase {
//  func testGroup() {
//    let op1 = BlockOperation {
//      print("1")
//      sleep(1)
//    }
//    op1.queuePriority = .high
//    let op2 = BlockOperation {
//      print("2")
//      sleep(1)
//    }
//    let q = OperationQueue.serial()
//    let group = GroupOperation(underlyingQueue: q, operations: [op1, op2])
//    let finishedExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: group, expectedValue: true)
//    q.addOperation(group)
//     wait(for: [finishedExpectation], timeout: 50, enforceOrder: true)
//
//  }

  func testExample() throws {
    var i = 0
    func count() -> Int {
      i += 1
      return i
    }

    let repeatOperation = DummyOperation(block: count)
    repeatOperation.installLogger()
    repeatOperation.input = "*"
    let loop = LoopOperation(operation: repeatOperation)
    loop.installLogger()
    let finishedExpectation = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: loop, expectedValue: true)
    loop.start()
     wait(for: [finishedExpectation], timeout: 5, enforceOrder: true)
  }

/**
Unless the property has been set, there is no underlying queue for an NSOperationQueue. An NSOperationQueue which hasn't been told to just use a specific one may use (start operations on) MANY different dispatch queues,

   3
   2
   5
   6
   4
   1

   **/

//  func test_investigation2() {
//    let op1 = BlockOperation {
//      print("1")
//      sleep(1)
//    }
//    let op2 = BlockOperation {
//      print("2")
//      sleep(1)
//    }
//    let op3 = BlockOperation {
//      print("3")
//      sleep(1)
//    }
//
//    let op4 = BlockOperation {
//      print("4")
//      sleep(1)
//    }
//    let op5 = BlockOperation {
//      print("5")
//      sleep(1)
//    }
//
//    op1.qualityOfService = .background
//    op2.qualityOfService = .utility
//    op3.qualityOfService = .default
//    op4.qualityOfService = .userInitiated
//    op5.qualityOfService = .userInteractive
//
//    let ops = [op1, op2, op3, op4, op5]
//
//
////    let queue = OperationQueue()
////    queue.maxConcurrentOperationCount = 10
////    let tq2 = DispatchQueue(label: "ciao2", attributes: .concurrent)
////    queue.underlyingQueue = tq2
////    //queue.addOperations(ops, waitUntilFinished: true)
////    queue.isSuspended = true
////    ops.forEach { (o) in
////      queue.addOperation(o)
////    }
////    queue.isSuspended = false
////    queue.waitUntilAllOperationsAreFinished()
//
////    let tq = DispatchQueue(label: "ciao")
////    let tq2 = DispatchQueue(label: "ciao2", attributes: .concurrent, target: tq)
////    let group = GroupOperation(underlyingQueue: tq2, operations: op1, op2, op3, op4, op5, op6)
////    group.maxConcurrentOperationCount = 10
////    let queue = OperationQueue()
////    queue.underlyingQueue = tq2
//
//    let tq2 = DispatchQueue(label: "ciao2") //, attributes: .concurrent)
//    let queue1 = OperationQueue()
//    let group = GroupOperation(underlyingQueue: tq2, operations: ops)
//    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: group, expectedValue: true)
//    queue1.addOperation(group)
//    wait(for: [expectation1], timeout: 10)
//
//  }

  func test_investigation() {
    let q = DispatchQueue(label: "ciao", attributes: .concurrent)
    //let q = DispatchQueue(label: "ciao")

    let opQueue1 = OperationQueue()
    let opQueue2 = OperationQueue()
    opQueue1.maxConcurrentOperationCount = 10
    opQueue2.maxConcurrentOperationCount = 10

    opQueue1.isSuspended = true
    opQueue2.isSuspended = true

    opQueue1.underlyingQueue = q
    opQueue2.underlyingQueue = q

    opQueue1.addOperation {
      print("1-1 \(Thread.current)"); sleep(1)
    }
    opQueue1.addOperation {
      print("1-2 \(Thread.current)"); sleep(1)
    }
    opQueue1.addOperation {
      print("1-3 \(Thread.current)"); sleep(1)
    }

    opQueue2.addOperation {
      print("2-1 \(Thread.current)"); sleep(1)
    }
    opQueue2.addOperation {
      print("2-2 \(Thread.current)"); sleep(1)
    }

    let bo = BlockOperation {
      print("2-3 \(Thread.current)"); sleep(1)
    }
    bo.qualityOfService = .userInteractive
    opQueue2.addOperation(bo)
//    opQueue2.addOperation {
//      print("2-3 \(Thread.current)"); sleep(1)
//    }

    opQueue1.isSuspended = false
    opQueue2.isSuspended = false

    sleep(15)

  }
}

extension LoopOperation: LoggableOperation { }

class DummyOperation: Operation, InputConsumingOperation & OutputProducingOperation, CopyingOperation, LoggableOperation {
  var input: String?
  var output: String?
  private let block: () -> Int

  init(block: @escaping () -> Int) {
    self.block = block
  }

  override func main() {
    guard let input = input else { return }

    print("running: \(input)")

    let value = self.block()

    if value >= 10 {
      output = nil
    } else {
      output = input + "*"
    }

  }

  func makeNew() -> Self {
    let operation = DummyOperation(block: block)
    operation.installLogger()
    return operation as! Self
  }
}
