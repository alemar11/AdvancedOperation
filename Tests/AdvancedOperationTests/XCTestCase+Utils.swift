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

  func XCTAssertSameErrorQuantity(errors: [Error], expectedErrors: [Error], file: String = #file, line: Int = #line) {
    guard checkSameErrorQuantity(generatedErrors: errors, expectedErrors: expectedErrors) else {
      return recordFailure(withDescription: "Operation has \(errors.count) errors, expected: \(expectedErrors.count)", inFile: file, atLine: line, expected: true)
    }
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
