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
import Dispatch
import XCTest
import os.log
@testable import AdvancedOperation

// MARK: - AsynchronousBlockOperation

final internal class SleepyAsyncOperation: AsynchronousOperation {
    private let interval1: UInt32
    private let interval2: UInt32
    private let interval3: UInt32
    
    init(interval1: UInt32 = 1, interval2: UInt32 = 1, interval3: UInt32 = 1) {
        self.interval1 = interval1
        self.interval2 = interval2
        self.interval3 = interval3
        super.init()
    }
    
    override func main() {
        DispatchQueue.global().async {
            if self.isCancelled {
                self.finish()
                return
            }
            
            sleep(self.interval1)
            
            if self.isCancelled {
                self.finish()
                return
            }
            
            sleep(self.interval2)
            
            if self.isCancelled {
                self.finish()
                return
            }
            
            sleep(self.interval3)
            self.finish()
        }
    }
}

// MARK: - AsynchronousInputOutputOperation

/// This operation fails if the input is greater than **1000**
/// This operation cancels itself if the input is **100**
internal class IntToStringAsyncOperation: AsynchronousOperation, InputConsumingOperation, OutputProducingOperation {
    var input: Int?
    private(set) var output: String?
    
    override func main() {
        DispatchQueue.global().async {
            if let input = self.input {
                self.output = "\(input)"
            }
            self.finish()
        }
    }
}

internal class StringToIntAsyncOperation: AsynchronousOperation, InputConsumingOperation, OutputProducingOperation {
    var input: String?
    private(set) var output: Int?
    
    override func main() {
        DispatchQueue.global().async {
            if let input = self.input {
                self.output = Int(input)
            }
            self.finish()
        }
    }
}

// MARK: - AsynchronousOperation

final internal class NotExecutableOperation: AsynchronousOperation {
    override func main() {
        XCTFail("This operation shouldn't be executed.")
        self.finish()
    }
}

final internal class AutoCancellingAsyncOperation: AsynchronousOperation {
    override func main() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.cancel()
            self.finish()
        }
    }
}

final internal class RunUntilCancelledAsyncOperation: AsynchronousOperation {
    let queue: DispatchQueue
    
    init(queue: DispatchQueue = DispatchQueue.global()) {
        self.queue = queue
    }
    
    override func main() {
        queue.async {
            while !self.isCancelled {
                sleep(1)
            }
            self.finish()
        }
    }
}

// MARK: - Operation

internal final class IntToStringOperation: AdvancedOperation & InputConsumingOperation & OutputProducingOperation {
    var input: Int?
    private(set) var output: String?
    
    override func main() {
        if let input = self.input {
            output = "\(input)"
        }
    }
}

internal final class StringToIntOperation: AdvancedOperation & InputConsumingOperation & OutputProducingOperation  {
    var input: String?
    private(set) var output: Int?
      
    override func main() {
        if let input = self.input {
            output = Int(input)
        }
    }
}

// MARK: - AdvancedOperation

internal final class FailingOperation: Operation, FailableOperation, TrackableOperation {
  private(set) var error: Error?
  
  override func main() {
    self.error = NSError(domain: identifier, code: 0, userInfo: nil) // TODO: errors
  }
}

// MARK: - Preconditions

struct NoCancelledDependencies: Precondition {
  func evaluate(for operation: AdvancedOperation, completion: @escaping (Result<Void, Error>) -> Void) {
    if operation.hasSomeCancelledDependencies {
      completion(.failure(NSError(domain: identifier, code: 1, userInfo: nil)))
    } else {
      completion(.success(()))
    }
  }
}

struct NoFailedDependencies: Precondition {
  func evaluate(for operation: AdvancedOperation, completion: @escaping (Result<Void, Error>) -> Void) {
    if operation.hasSomeFailedDependencies {
      completion(.failure(NSError(domain: identifier, code: 1, userInfo: nil)))
    } else {
      completion(.success(()))
    }
  }
}
