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

final internal class SleepyAsyncOperation: AsynchronousOutputOperation<Never> {
    private let interval1: UInt32
    private let interval2: UInt32
    private let interval3: UInt32
    
    init(interval1: UInt32 = 1, interval2: UInt32 = 1, interval3: UInt32 = 1) {
        self.interval1 = interval1
        self.interval2 = interval2
        self.interval3 = interval3
        super.init()
    }
    
    override func execute(result: @escaping (Result<Never?, Error>) -> Void) {
        DispatchQueue.global().async { [weak weakSelf = self] in
            
            guard let strongSelf = weakSelf else {
                result(.success(nil))
                return
            }
            
            if strongSelf.isCancelled {
                result(.success(nil))
                return
            }
            
            sleep(self.interval1)
            
            if strongSelf.isCancelled {
                result(.success(nil))
                return
            }
            
            sleep(self.interval2)
            
            if strongSelf.isCancelled {
                result(.success(nil))
                return
            }
            
            sleep(self.interval3)
            result(.success(nil))
        }
    }
}

// MARK: - AsynchronousInputOutputOperation

/// This operation fails if the input is greater than **1000**
/// This operation cancels itself if the input is **100**
internal class IntToStringAsyncOperation: AsynchronousInputOutputOperation<Int, String> {
    override func execute(result: @escaping (Result<String?, Error>) -> Void) {
        DispatchQueue.global().async {
            if let input = self.input {
                result(.success("\(input)"))
            } else {
                result(.success(nil))
            }
        }
    }
}

internal class StringToIntAsyncOperation: AsynchronousInputOutputOperation<String, Int>  {
    override func execute(result: @escaping (Result<Int?, Error>) -> Void) {
        DispatchQueue.global().async {
            if let input = self.input, let value = Int(input) {
                result(.success(value))
            } else {
                result(.success(nil))
            }
        }
    }
}

// MARK: - AsynchronousOperation

final internal class NotExecutableOperation: AsynchronousOperation {
    override func execute(completion: @escaping (Finish) -> Void) {
        XCTFail("This operation shouldn't be executed.")
        completion(.success)
    }
}


final internal class AutoCancellingAsyncOperation: AsynchronousOperation {
    override func execute(completion: @escaping (Finish) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak weakSelf = self] in
            guard let strongSelf = weakSelf else {
                completion(.success)
                return
            }
            strongSelf.cancel()
            completion(.success)
        }
    }
}

final internal class RunUntilCancelledAsyncOperation: AsynchronousOperation {
    let queue: DispatchQueue
    
    init(queue: DispatchQueue = DispatchQueue.global()) {
        self.queue = queue
    }
    
    override func execute(completion: @escaping (Finish) -> Void) {
        queue.async {
            while !self.isCancelled {
                sleep(1)
            }
            completion(.success)
        }
    }
}

// MARK: - Operation

internal class IntToStringOperation: Operation & InputConsuming & OutputProducing {
    var input: Int?
    var output: String? {
        return _output.value
    }
    
    private var _output = Atomic<String?>(nil)
    
    override func main() {
        if let input = input {
            _output.mutate {
                $0 = "\(input)"
            }
        }
    }
}

internal class StringToIntOperation: Operation & InputConsuming & OutputProducing  {
    var input: String?
    var output: Int? {
        return _output.value
    }
    
    private var _output = Atomic<Int?>(nil)
    
    override func main() {
        if let input = input {
            _output.mutate {
                $0 = Int(input)
            }
        }
    }
}
