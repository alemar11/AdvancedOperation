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

import Dispatch
import Foundation

public typealias AsyncOutputOperation = AsynchronousOutputOperation

/// An abstract  subclass of `AsynchronousOperation` to build output producing asynchronous operations.
open class AsynchronousOutputOperation<OutputType>: AsyncOperation, OutputProducing {
    // MARK: - Public Properties
    
    /// The output produced once `self` is finished.
    public private(set) var output: OutputType? = nil
    
    // MARK: - PRivate Properties
    
    private let gate = Atomic(false)
    
    // MARK: - Public Methods
    
    public final override func execute(completion: @escaping (Finish) -> Void) {
        self.execute(result: { result in
            let completable =  self.gate.mutate { value -> Bool in
                if value {
                    assertionFailure("The completion block can't be called multiple times")
                    return false
                } else {
                    value = true
                    return true
                }
            }
            
            guard completable else { return }
            
            do {
                self.output = try result.get()
                completion(.success)
            } catch {
                completion(.failure(error: error))
            }
        })
        
    }
    
    open func execute(result: @escaping (Result<Output, Error>) -> Void) {
        preconditionFailure("Subclasses must implement `execute(completion:)`.")
    }
}
