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

import XCTest
@testable import AdvancedOperation

class InjectionTests: XCTestCase {
  func testInputAndOutput() {
    let operation1 = IntToStringOperation()
    operation1.input = 10
    operation1.start()
    XCTAssertEqual(operation1.output, "10")

    let operation2 = StringToIntOperation()
    operation2.input = "10"
    operation2.start()
    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionUsingClassMethodAndWaitUntilFinished() {
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    operation1.input = 10
    let adapterOperation = AdvancedOperation.injectOperation(operation1, into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionUsingInstanceMethodAndWaitUntilFinished() {
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    operation1.input = 10
    let adapterOperation = operation1.inject(into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, 10)
  }

  func testTransformableInjectionInstanceMethodAndWaitUntilFinishedUsing() {
    let operation1 = IntToStringOperation()
    let operation2 = IntToStringOperation()
    operation1.input = 10
    let adapterOperation = operation1.inject(into: operation2) { value -> Int? in
      if let value = value {
        return Int(value)
      } else {
        return nil
      }
    }
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertEqual(operation2.output, "10")
  }

  func testTransformableInjectionWithNilResultUsingInstanceMethodAndWaitUntilFinished() {
    let operation1 = IntToStringOperation()
    let operation2 = IntToStringOperation()
    operation1.input = 404
    let adapterOperation = operation1.inject(into: operation2) { value -> Int? in
      if let value = value {
        return Int(value)
      } else {
        return nil
      }
    }
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: true)

    XCTAssertNil(operation2.output)
  }

  func testInjectionWithoutWaitingUntilFinished() {
    let expectation = self.expectation(description: "\(#function)\(#line)")
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    let operation3 = AdvancedBlockOperation {
      expectation.fulfill()
    }
    operation3.addDependency(operation2)

    operation1.input = 10
    let adapterOperation = AdvancedOperation.injectOperation(operation1, into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation, operation3], waitUntilFinished: false)

    waitForExpectations(timeout: 3)
    XCTAssertEqual(operation2.input, "10")
    XCTAssertEqual(operation2.output, 10)
  }

  func testInjectionInputNotOptionalRequirement() {
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let operation1 = IntToStringOperation()
    let operation2 = StringToIntOperation()
    operation2.completionBlock = {
      expectation1.fulfill()
    }
    operation1.input = 2000 // values greater than 1000 will produce a nil output when executing 😎
    let adapterOperation = operation1.inject(into: operation2)
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: false)

    waitForExpectations(timeout: 3)
    XCTAssertNil(operation2.input)
    XCTAssertNil(operation2.output)
    XCTAssertTrue(operation2.isCancelled)
  }

  func testInjectionInputUsingSuccessFulRequirement() {
    let expectation1 = self.expectation(description: "\(#function)\(#line)")
    let operation1 = IntToStringOperation() // no input -> fails
    let operation2 = StringToIntOperation()
    operation2.completionBlock = {
      expectation1.fulfill()
    }

    let adapterOperation = operation1.inject(into: operation2, requirements: [.successful])
    let queue = AdvancedOperationQueue()
    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: false)

    waitForExpectations(timeout: 3)
    XCTAssertNil(operation2.input)
    XCTAssertNil(operation2.output)
    XCTAssertTrue(operation2.isCancelled)
  }

  func testInjectionInputUsingNoCancellationRequirement() {
    let operation1 = IntToStringOperation() // no input -> fails
    let operation2 = StringToIntOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation2, expectedValue: true)

    operation1.input = 100 // special value to cancel the operation when executing 😎

    let adapterOperation = operation1.inject(into: operation2, requirements: [.noCancellation])
    let queue = AdvancedOperationQueue()

    queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: false)

    wait(for: [expectation1, expectation2], timeout: 10)
    XCTAssertNil(operation2.input)
    XCTAssertNil(operation2.output)
  }

  func testStress() {
    (1...10_000).forEach { i in
      print("\t 🚩", i)
      testInputInjectionWithAnAlreadyCancelledOutputProducingOperationUsingNoCancellationRequirement()
      //testComposition()
    }
  }

//  func testComposition() {
//    let op1 = AdvancedBlockOperation { }
//    let op2 = AdvancedBlockOperation { complete in complete([]) }
//    let op3 = AdvancedBlockOperation { }
//    op3.addDependency(op2)
//    op2.addDependency(op1)
//    op1.cancel()
//
//    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: op3, expectedValue: true)
//    //let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation2, expectedValue: true)
//
//    let queue = AdvancedOperationQueue()
//    queue.addOperations([op2, op3], waitUntilFinished: false)
//
//     wait(for: [expectation1], timeout: 10)
//  }

  func testInputInjectionWithAnAlreadyCancelledOutputProducingOperationUsingNoCancellationRequirement() {
    let operation1 = IntToStringOperation() // no input -> fails
    let operation2 = StringToIntOperation()
    let expectation1 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isCancelled), object: operation2, expectedValue: true)
    let expectation2 = XCTKVOExpectation(keyPath: #keyPath(AdvancedOperation.isFinished), object: operation2, expectedValue: true)


    operation1.log = TestsLog
    operation2.log = TestsLog
    //operation1.input = 100 // special value to cancel the operation when executing 😎

    let adapterOperation = operation1.inject(into: operation2, requirements: [.noCancellation])
    //adapterOperation.log = TestsLog
    let queue = AdvancedOperationQueue() //AdvancedOperationQueue()
    operation1.cancel()
    //queue.addOperations([operation1, operation2, adapterOperation], waitUntilFinished: false)
    queue.addOperation(operation1)
    queue.addOperation(adapterOperation)
    queue.addOperation(operation2) //TODO: is the order important?

    wait(for: [expectation1, expectation2], timeout: 20)
    print("R", adapterOperation.isReady, "E", adapterOperation.isExecuting, "C", adapterOperation.isCancelled, "F", adapterOperation.isFinished)
    for operation in queue.operations {
      print(operation.operationName, "-->", operation.dependencies.map({ $0.operationName}))
    }

    XCTAssertNil(operation2.input)
    XCTAssertNil(operation2.output)
  }

  func testInvestigation() {
    do {
      let queue = OperationQueue()

      let blockOperation = TestBlockOperation()
      blockOperation.addExecutionBlock({ [unowned blockOperation] in
        DispatchQueue.global().async {
          for i in 0 ..< 10000 {
            if blockOperation.isCancelled {
              print("Cancelled")
              return // or break
            }
            print(i)
          }
        }

      })

      blockOperation.start()
      //queue.addOperation(blockOperation)

      Thread.sleep(forTimeInterval: 0.5)
      blockOperation.cancel()
      print("---------")
    }
  }

  func testY() {
     let operation1 = BlockOperation()
     let expectation1 = XCTKVOExpectation(keyPath: #keyPath(Operation.isFinished), object: operation1, expectedValue: true)
//    let token = operation1.observe(\.isExecuting, options: [.old, .new]) { (op, changes) in
//      print(changes)
//    }
    operation1.cancel()
    print(operation1.isReady)
    let queue = OperationQueue()
    queue.addOperation(operation1)


    wait(for: [expectation1], timeout: 10)
    print(operation1.isReady, operation1.isCancelled, operation1.isFinished)
  }

  func testX() {
    let op = AdvancedBlockOperation2 {_ in
        DispatchQueue.global().async {
      print("10")
      }
    }
    op.start()
    XCTAssertTrue(op.isFinished)
  }
}

class TestBlockOperation: BlockOperation {
  deinit {
    print("No retain cycle")
  }
}



// 3 adv op
// adv block op
// log when start is called

/**

 2943
 2019-06-23 09:42:42.836214+0200 xctest[82269:3659980] [Tests] IntToStringOperation is cancelling.
 2019-06-23 09:42:42.836897+0200 xctest[82269:3659980] [Tests] IntToStringOperation has been cancelled with 0 errors.
 start 1 IntToStringOperation
 start 2 IntToStringOperation
 2019-06-23 09:42:42.837332+0200 xctest[82269:3660126] [Tests] IntToStringOperation is finishing.
 start 1 AdvancedBlockOperation
 main AdvancedBlockOperation
 2019-06-23 09:42:42.837736+0200 xctest[82269:3660126] [Tests] IntToStringOperation has finished with 0 errors.
 executing AdvancedBlockOperation
 2019-06-23 09:42:42.838081+0200 xctest[82269:3660272] [Tests] StringToIntOperation is cancelling.
 2019-06-23 09:42:42.838572+0200 xctest[82269:3660272] [Tests] StringToIntOperation has been cancelled with 1 errors.
 start 1 StringToIntOperation
 start 2 StringToIntOperation
 start 2 AdvancedBlockOperation
 2019-06-23 09:42:42.839467+0200 xctest[82269:3660131] [Tests] StringToIntOperation is finishing.
 2019-06-23 09:42:42.839884+0200 xctest[82269:3660131] [Tests] StringToIntOperation has finished with 1 errors.
 R true E false C false F true
 2944
 2019-06-23 09:42:42.842758+0200 xctest[82269:3659980] [Tests] IntToStringOperation is cancelling.
 2019-06-23 09:42:42.889354+0200 xctest[82269:3659980] [Tests] IntToStringOperation has been cancelled with 0 errors.
 start 1 IntToStringOperation
 start 2 IntToStringOperation
 2019-06-23 09:42:42.889889+0200 xctest[82269:3660131] [Tests] IntToStringOperation is finishing.
 2019-06-23 09:42:42.890234+0200 xctest[82269:3660131] [Tests] IntToStringOperation has finished with 0 errors.
 <unknown>:0: error: -[AdvancedOperation_Tests_iOS.InjectionTests testStress] : Asynchronous wait failed: Exceeded timeout of 10 seconds, with unfulfilled expectations: "Expect value of 'finished' of <AdvancedOperation_Tests_iOS.StringToIntOperation: 0x7b4800362d00> to be '1'", "Expect value of 'cancelled' of <AdvancedOperation_Tests_iOS.StringToIntOperation: 0x7b4800362d00> to be '1'".
 R true E false C false F false



 start 2 AdvancedBlockOperation
 <unknown>:0: error: -[AdvancedOperation_Tests_iOS.InjectionTests testStress] : Asynchronous wait failed: Exceeded timeout of 10 seconds, with unfulfilled expectations: "Expect value of 'finished' of <AdvancedOperation_Tests_iOS.StringToIntOperation: 0x7b48006df500> to be '1'".
 R true E false C false F true
 StringToIntOperation --> ["AdvancedBlockOperation"]


 🚩 2009
 2019-06-23 22:22:10.368296+0200 xctest[89460:4298096] [Tests] IntToStringOperation is cancelling.
 2019-06-23 22:22:10.368609+0200 xctest[89460:4298096] [Tests] IntToStringOperation has been cancelled with 0 errors.
 2019-06-23 22:22:10.398899+0200 xctest[89460:4298146] [Tests] IntToStringOperation is finishing.
 2019-06-23 22:22:10.399331+0200 xctest[89460:4298146] [Tests] IntToStringOperation has finished with 0 errors.
 executing AdvancedBlockOperation2
 2019-06-23 22:22:10.399648+0200 xctest[89460:4298132] [Tests] StringToIntOperation is cancelling.
 2019-06-23 22:22:10.400265+0200 xctest[89460:4298132] [Tests] StringToIntOperation has been cancelled with 1 errors.
 finished AdvancedBlockOperation2 true
 2019-06-23 22:22:10.401032+0200 xctest[89460:4298132] [Tests] StringToIntOperation is finishing.
 2019-06-23 22:22:10.401959+0200 xctest[89460:4298132] [Tests] StringToIntOperation has finished with 1 errors.
 R true E false C false F true
 🚩 2010
 2019-06-23 22:22:10.405702+0200 xctest[89460:4298096] [Tests] IntToStringOperation is cancelling.
 2019-06-23 22:22:10.406422+0200 xctest[89460:4298096] [Tests] IntToStringOperation has been cancelled with 0 errors.
 2019-06-23 22:22:10.406935+0200 xctest[89460:4298146] [Tests] IntToStringOperation is finishing.
 2019-06-23 22:22:10.407314+0200 xctest[89460:4298146] [Tests] IntToStringOperation has finished with 0 errors.
 executing AdvancedBlockOperation2
 2019-06-23 22:22:10.407652+0200 xctest[89460:4298131] [Tests] StringToIntOperation is cancelling.
 2019-06-23 22:22:10.408216+0200 xctest[89460:4298131] [Tests] StringToIntOperation has been cancelled with 1 errors.
 finished AdvancedBlockOperation2 true
 <unknown>:0: error: -[AdvancedOperation_Tests_iOS.InjectionTests testStress] : Asynchronous wait failed: Exceeded timeout of 20 seconds, with unfulfilled expectations: "Expect value of 'finished' of <AdvancedOperation_Tests_iOS.StringToIntOperation: 0x7b480029a300> to be '1'".
 R true E false C false F true
 StringToIntOperation --> ["AdvancedBlockOperation2"]
 */
