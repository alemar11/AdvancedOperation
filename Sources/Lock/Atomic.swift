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

import Dispatch

/// A wrapper for atomic read/write access to a value.
/// The value is protected by a serial `DispatchQueue`.
public final class Atomic2<A> {
  private var _value: A
  private let queue: DispatchQueue
  
  /// Creates an instance of `Atomic` with the specified value.
  ///
  /// - Paramater value: The object's initial value.
  /// - Parameter targetQueue: The target dispatch queue for the "lock queue".
  ///   Use this to place the atomic value into an existing queue hierarchy
  ///   (e.g. for the subsystem that uses this object).
  ///   See Apple's WWDC 2017 session 706, Modernizing Grand Central Dispatch
  ///   Usage (https://developer.apple.com/videos/play/wwdc2017/706/), for
  ///   more information on how to use target queues effectively.
  ///
  ///   The default value is `nil`, which means no target queue will be set.
  public init(_ value: A, targetQueue: DispatchQueue? = nil) {
    _value = value
    queue = DispatchQueue(label: "com.olebegemann.Atomic", target: targetQueue)
  }
  
  /// Read access to the wrapped value.
  public var value: A {
    return queue.sync { _value }
  }
  
  /// Mutations of `value` must be performed via this method.
  ///
  /// If `Atomic` exposed a setter for `value`, constructs that used the getter
  /// and setter inside the same statement would not be atomic.
  ///
  /// Examples that would not actually be atomic:
  ///
  ///     let atomicInt = Atomic(42)
  ///     // Calls getter and setter, but value may have been mutated in between
  ///     atomicInt.value += 1
  ///
  ///     let atomicArray = Atomic([1,2,3])
  ///     // Mutating the array through a subscript causes both a get and a set,
  ///     // acquiring and releasing the lock twice.
  ///     atomicArray[1] = 42
  ///
  /// See also: https://github.com/ReactiveCocoa/ReactiveSwift/issues/269
  public func mutate(_ transform: (inout A) -> Void) {
    queue.sync {
      transform(&_value)
    }
  }
}

extension Atomic2: Equatable where A: Equatable {
  public static func ==(lhs: Atomic2, rhs: Atomic2) -> Bool {
    return lhs.value == rhs.value
  }
}

extension Atomic2: Hashable where A: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}
