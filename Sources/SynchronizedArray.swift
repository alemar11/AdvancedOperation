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

import Dispatch
import Foundation

internal final class SynchronizedArray<Element> {
  fileprivate let queue = DispatchQueue(label: "\(identifier).SynchronizedArray")
  fileprivate var array = [Element]()
}

// MARK: - Properties
internal extension SynchronizedArray {

  /// Returns all the elements in the underlying array.
  /// - Note: Use this property only for read operations.
  var all: [Element] {
    return queue.sync { self.array }
  }

  /// Returns the first element of the sequence that satisfies the given predicate.
  func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
    return try queue.sync {
      try self.array.first(where: predicate)
    }
  }

  var isEmpty: Bool {
    return queue.sync {
      self.array.isEmpty
    }
  }

}

// MARK: - Mutable
internal extension SynchronizedArray {

  /// Adds a new element at the end of the array.
  ///
  /// - Parameter element: The element to append to the array.
  func append(contentsOf elements: [Element]) {
    queue.sync {
      guard !elements.isEmpty else {
        return // avoid TSAN _swiftEmptyArrayStorage
      }

      self.array.append(contentsOf: elements)
    }
  }

  /// Adds a new element at the end of the array.
  func append(_ element: Element) {
    queue.sync {
      self.array.append(element)
    }
  }

  /// Returns an array containing the non-nil results of calling the given transformation with each element of this sequence.
  func compactMap<K>(transform: (Element) throws -> K?) rethrows -> [K] {
    return try queue.sync {
      if self.array.isEmpty { // TSAN _swiftEmptyArrayStorage
        return []
      }
      let result = try self.array.compactMap(transform)
      return result
    }
  }

  func removeAll() {
    return queue.sync {
      self.array.removeAll()
    }
  }

}
