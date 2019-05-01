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

import Foundation

internal extension AdvancedOperation {
  /// The possible internal states an AdvancedOperation can be in.
  enum State: Int, CustomDebugStringConvertible {
    case pending
    case executing
    case finished

    /// Determines wheter or not a transition between the current state and another one is possible.
    func canTransition(to state: State) -> Bool {
      switch (self, state) {
      case (.pending, .executing):
        return true
      case (.pending, .finished):
        return true
      case (.executing, .finished):
        return true
      default:
        return false
      }
    }

   /// The `#keyPath` for the `Operation` property that's associated with this value.
    var objcKeyPath: String? {
      switch self {
      case .pending: return nil
      case .executing: return #keyPath(isExecuting)
      case .finished: return #keyPath(isFinished)
      }
    }

    var debugDescription: String {
      switch self {
      case .pending:
        return "pending"
      case .executing:
        return "executing"
      case .finished:
        return "finished"
      }
    }
  }
}
