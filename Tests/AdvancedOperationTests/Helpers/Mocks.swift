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
import Dispatch
import XCTest
import os.log
@testable import AdvancedOperation

// MARK: - OSLog

let TestsLog = OSLog(subsystem: identifier, category: "Tests")

// MARK: - Error

internal enum MockError: Swift.Error, Equatable {
  case test
  case failed
  case cancelled(date: Date)
  case generic(date: Date)
  
  static func ==(lhs: MockError, rhs: MockError) -> Bool {
    switch (lhs, rhs) {
    case (.test, .test):
      return true
    case (.failed, .failed):
      return true
    case (let .cancelled(dateLhs), let .cancelled(dateRhs)):
      return dateLhs == dateRhs
    case (let .generic(dateLhs), let .generic(dateRhs)):
      return dateLhs == dateRhs
    default:
      return false
    }
  }
}

// MARK: - AsynchronousOperation

class NotFinishingAsynchronousOperation: AsynchronousOperation<Void> {
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    
  }
}

final internal class SleepyAsyncOperation: AsynchronousOperation<Void> {
  private let interval1: UInt32
  private let interval2: UInt32
  private let interval3: UInt32
  
  init(interval1: UInt32 = 1, interval2: UInt32 = 1, interval3: UInt32 = 1) {
    self.interval1 = interval1
    self.interval2 = interval2
    self.interval3 = interval3
    super.init()
  }
  
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.global().async { [weak weakSelf = self] in

      guard let strongSelf = weakSelf else {
        completion(.failure(MockError.test))
        return
      }
      
      if strongSelf.isCancelled {
        completion(.failure(MockError.cancelled(date: Date())))
        return
      }
      
      sleep(self.interval1)
      
      if strongSelf.isCancelled {
        completion(.failure(MockError.cancelled(date: Date())))
        return
      }
      
      sleep(self.interval2)
      
      if strongSelf.isCancelled {
        completion(.failure(MockError.cancelled(date: Date())))
        return
      }
      
      sleep(self.interval3)
      completion(.success(Void()))
    }
  }
}

/// This operation fails if the input is greater than **1000**
/// This operation cancels itself if the input is **100**
internal class IntToStringAsyncOperation: AsynchronousOperation<String> & InputConsuming {
  var input: Int?
  
  override func execute(completion: @escaping (Result<String, Error>) -> Void) {
    if isCancelled {
      completion(.failure(NSError.AdvancedOperation.cancelled))
      return
    }
    
    guard let input = self.input else {
      completion(.failure(MockError.failed))
      return
    }
    
    if input == 100 {
      cancel()
      assert(self.isCancelled)
      completion(.success("\(input)"))
    } else if input <= 1000 {
      completion(.success("\(input)"))
    } else {
      completion(.failure(MockError.failed))
    }
  }
}

internal class StringToIntAsyncOperation: AsynchronousOperation<Int> & InputConsuming  {
  var input: String?
  
  override func execute(completion: @escaping (Result<Int, Error>) -> Void) {
    if isCancelled {
      completion(.failure(NSError.AdvancedOperation.cancelled))
      return
    }
    if let input = self.input, let value = Int(input) {
      completion(.success(value))
    } else {
      completion(.failure(MockError.failed))
    }
  }
}


final internal class CancellingAsyncOperation: AsynchronousOperation<Void> {
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else {
        completion(.failure(MockError.cancelled(date: Date())))
        return
      }
      strongSelf.cancel()
      completion(.failure(MockError.cancelled(date: Date())))
    }
  }
}

/// An operation that finishes with errors
final internal class FailingAsyncOperation: AsynchronousOperation<Void> {
  private let defaultError: Error
  
  init(error: MockError = MockError.failed) {
    self.defaultError = error
  }
  
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak weakSelf = self] in
      guard let strongSelf = weakSelf else {
        completion(.failure(MockError.failed))
        return
      }
      completion(.failure(strongSelf.defaultError))
    }
  }
}

final internal class RunUntilCancelledAsyncOperation: AsynchronousOperation<Void> {
  let queue: DispatchQueue
  
  init(queue: DispatchQueue = DispatchQueue.global()) {
    self.queue = queue
  }
  
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    queue.async {
      while !self.isCancelled {
        sleep(1)
      }
      completion(.success(()))
    }
  }
}

final internal class NotExecutableOperation: AsynchronousOperation<Void> {
  override func execute(completion: @escaping (Result<Void, Error>) -> Void) {
    XCTFail("This operation shouldn't be executed.")
    completion(.failure(MockError.test))
  }
}


// MARK: - Operation

internal class IntToStringOperation: Operation & InputConsuming & OutputProducing {
  var input: Int?
  private(set) var output: String?

  override func main() {
    if let input = input {
      output = "\(input)"
    }
  }
}

internal class StringToIntOperation:  Operation & InputConsuming & OutputProducing  {
  var input: String?
  private(set) var output: Int?

  override func main() {
    if let input = input {
      output = Int(input)
    }
  }
}