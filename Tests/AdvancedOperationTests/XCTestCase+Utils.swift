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

import Foundation
import XCTest
@testable import AdvancedOperation

extension XCTestCase {

  // It appears that on Linux, the operation readiness is ALWAYS set to 'false' by default.
  // It changes to 'true' ONLY if an operation is added to an OperationQueue regardless of its associated dependencies.
  private func defaultReadiness() -> Bool {
    #if !os(Linux)
      return true
    #else
      return false
    #endif
  }

  /// Asserts that the Operation has the default ready state.
  /// - Note: It appears that on Linux, the operation readiness is ALWAYS set to 'false' by default. It changes to 'true' ONLY if an operation is added to an OperationQueue regardless of its associated dependencies.
  func XCTAssertDefaultReadiness(operation: Operation, file: String = #file, line: Int = #line) {
    guard operation.isReady == defaultReadiness() else {
      return recordFailure(withDescription: "Operation hasn't the default ready state (\(defaultReadiness()).", inFile: file, atLine: line, expected: true)
    }
  }


  /// Asserts that the AdvancedOperation can be started anytime.
  func XCTAssertOperationCanBeStarted(operation: AdvancedOperation, file: String = #file, line: Int = #line) {

    guard
      operation.isReady == defaultReadiness(),
      !operation.isExecuting,
      !operation.isCancelled,
      !operation.isFinished
      else { return recordFailure(withDescription: "Operation cannot be started.", inFile: file, atLine: line, expected: true) }
  }

  /// Asserts that the AdvancedOperation is currently executing.
  func XCTAssertOperationExecuting(operation: AdvancedOperation, file: String = #file, line: Int = #line) {

    guard
      operation.isReady == defaultReadiness(),
      operation.isExecuting,
      !operation.isCancelled,
      !operation.isFinished
      else { return recordFailure(withDescription: "Operation is not executing.", inFile: file, atLine: line, expected: true) }
  }

  /// Asserts that the AdvancedOperation has finished due to a cancel command.
  func XCTAssertOperationCancelled(operation: AdvancedOperation, errors: [Error] = [], file: String = #file, line: Int = #line) {

    guard
      operation.isReady == defaultReadiness(),
      !operation.isExecuting,
      operation.isCancelled,
      operation.isFinished
      else { return recordFailure(withDescription: "Operation is not cancelled.", inFile: file, atLine: line, expected: true) }

    guard checkSameErrorQuantity(generatedErrors: operation.errors, expectedErrors: errors)
      else { return recordFailure(withDescription: "Operation has \(operation.errors.count) errors, expected: \(errors.count)", inFile: file, atLine: line, expected: true) }
  }

  /// Asserts that the AdvancedOperation has finished.
  func XCTAssertOperationFinished(operation: AdvancedOperation, errors: [Error] = [], file: String = #file, line: Int = #line) {

    guard
      operation.isReady == defaultReadiness(),
      !operation.isExecuting,
      !operation.isCancelled,
      operation.isFinished
      else { return recordFailure(withDescription: "Operation is not finished.", inFile: file, atLine: line, expected: true) }

    guard checkSameErrorQuantity(generatedErrors: operation.errors, expectedErrors: errors)
      else { return recordFailure(withDescription: "Operation has \(operation.errors.count) errors, expected: \(errors.count)", inFile: file, atLine: line, expected: true) }

  }

  /// Returns `true` if the generated operation's error are the same (as quantity) of the expected ones.
  private func checkSameErrorQuantity(generatedErrors: [Error], expectedErrors: [Error]) -> Bool {
    guard generatedErrors.count == expectedErrors.count else { return false }
    var generatedErrorsDictionary = [String: Int]()
    generatedErrors.forEach { (error) in
      let description = error.localizedDescription
      if let count = generatedErrorsDictionary[description] {
        generatedErrorsDictionary[description] = count + 1
      } else {
        generatedErrorsDictionary[description] = 1
      }
    }

    var expectedErrorsDictionary = [String: Int]()
    expectedErrors.forEach { (error) in
      let description = error.localizedDescription
      if let count = expectedErrorsDictionary[description] {
        expectedErrorsDictionary[description] = count + 1
      } else {
        expectedErrorsDictionary[description] = 1
      }
    }

    guard expectedErrorsDictionary.keys.count == generatedErrorsDictionary.keys.count else { return false }

    for key in expectedErrorsDictionary.keys {
      guard
        let expectedCount = expectedErrorsDictionary[key],
        let generatedCount = generatedErrorsDictionary[key]
        else { return false }

      guard expectedCount == generatedCount else { return false }
    }

    return true
  }

}
