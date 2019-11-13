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

// TODO: how can I improve this code?
/// Thread-safe access using a locking mechanism conforming to `NSLocking` protocol.
internal final class Atomic<T> {
  private var _value: T
  private let lock: NSLocking

  internal init(_ value: T, lock: NSLocking = UnfairLock()) {
    self.lock = lock
    self._value = value
  }

  internal var value: T {
    // Atomic properties with a setter are kind of dangerous in some scenarios
    // https://github.com/ReactiveCocoa/ReactiveSwift/issues/269
    lock.lock()
    defer { lock.unlock() }

    return _value
  }

  internal func read<U>(_ value: (T) throws -> U) rethrows -> U {
    lock.lock()
    defer { lock.unlock() }
    return try value(_value)
  }

  internal func mutate(_ transform: (inout T) throws -> Void) rethrows {
    lock.lock()
    defer { lock.unlock() }
    try transform(&_value)
  }

  internal func safeAccess<U>(_ transform: (inout T) throws -> U) rethrows -> U {
    lock.lock()
    defer { lock.unlock() }
    return try transform(&_value)
  }
}
