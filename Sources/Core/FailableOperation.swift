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

import Foundation

import Foundation

/// Operations conformin to this protocolor may generate an error while executing.
public protocol FailableOperation: Operation {
  /// The error  occurred during the operation evaluation.
  var error: Error? { get }
}

public extension FailableOperation {
  /// Returns `true` in the operation has finished with an error.
  var isFailed: Bool { return isFinished && error != nil }
}

public extension Operation {
  /// Returns `true` if at least one dependency conforming to `FailableOperation` has generated an error.
  var hasSomeFailedDependencies: Bool {
    return dependencies.first { ($0 as? FailableOperation)?.isFailed ?? false } != nil // TODO test
  }
}
