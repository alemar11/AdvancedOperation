// AdvancedOperation

import Foundation

// MARK: - Atomic

/// A mutex wrapper around contents.
/// Useful for threadsafe access to single values but less useful for compound values where different components might need to be updated at different times.
final class Atomic<T> {
  private var mutex = UnfairLock()
  private var internalValue: T

  @inlinable
  var value: T {
    mutex.lock()
    defer { mutex.unlock() }
    return internalValue
  }

  //  var isMutating: Bool {
  //    if mutex.try() {
  //      mutex.unlock()
  //      return false
  //    }
  //    return true
  //  }

  init(_ value: T) {
    internalValue = value
  }

  @discardableResult @inlinable
  func mutate<U>(_ transform: (inout T) throws -> U) rethrows -> U {
    mutex.lock()
    defer { mutex.unlock() }
    return try transform(&internalValue)
  }
}

// MARK: - UnfairLock

/// An object that coordinates the operation of multiple threads of execution within the same application.
final class UnfairLock: NSLocking {
  private var unfairLock: os_unfair_lock_t

  init() {
    unfairLock = .allocate(capacity: 1)
    unfairLock.initialize(to: os_unfair_lock())
  }

  func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }

  //  func `try`() -> Bool {
  //    return os_unfair_lock_trylock(unfairLock)
  //  }

  deinit {
    unfairLock.deinitialize(count: 1)
    unfairLock.deallocate()
  }
}
