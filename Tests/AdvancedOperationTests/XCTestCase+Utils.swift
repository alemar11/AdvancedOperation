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

  func XCTAssertOperationReady(operation: AdvancedOperation, file: String = #file, line: Int = #line) {

    guard
      operation.isReady,
      !operation.isExecuting,
      !operation.isCancelled,
      !operation.isFinished
      else { return recordFailure(withDescription: "Operation is not in ready state.", inFile: file, atLine: line, expected: true) }
  }

  func XCTAssertOperationExecuting(operation: AdvancedOperation, file: String = #file, line: Int = #line) {

    guard
      !operation.isReady,
      operation.isExecuting,
      !operation.isCancelled,
      !operation.isFinished
      else { return recordFailure(withDescription: "Operation is not in executing state.", inFile: file, atLine: line, expected: true) }
  }

  /// AdvancedOperation finished due to a cancel command.
  func XCTAssertOperationCancelled(operation: AdvancedOperation, errors: [Error] = [], file: String = #file, line: Int = #line) {

    guard
      !operation.isReady,
      !operation.isExecuting,
      operation.isCancelled,
      operation.isFinished
      else { return recordFailure(withDescription: "Operation is not in cancelled state.", inFile: file, atLine: line, expected: true) }

    guard operation.errors.count == errors.count
      else { return recordFailure(withDescription: "Operation has \(operation.errors.count) errors, expected: \(errors.count)", inFile: file, atLine: line, expected: true) }
  }

  /// AdvancedOperation finished due to a cancel command.
  func XCTAssertOperationFinished(operation: AdvancedOperation, errors: [Error] = [], file: String = #file, line: Int = #line) {

    guard
      !operation.isReady,
      !operation.isExecuting,
      !operation.isCancelled,
      operation.isFinished
      else { return recordFailure(withDescription: "Operation is not in finished state.", inFile: file, atLine: line, expected: true) }

    guard operation.errors.count == errors.count
      else { return recordFailure(withDescription: "Operation has \(operation.errors.count) errors, expected: \(errors.count)", inFile: file, atLine: line, expected: true) }
  }

}
