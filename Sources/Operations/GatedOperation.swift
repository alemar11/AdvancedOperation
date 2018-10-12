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

import Foundation

/// An operation whose the underlying operation execution depends on a the result (Bool) of a block.
/// - Note: if the result is `false` or an error is thrown, the operation will be cancelled.
open class GatedOperation<T: AdvancedOperation>: WrappedOperation<T> {
  
  public typealias Block = BlockCondition.Block
  
  public init(_ operation: T, exclusivityManager: ExclusivityManager = .sharedInstance, underlyingQueue: DispatchQueue? = .none, gate: @escaping Block) {
    let condition = BlockCondition(block: gate)
    
    /// There are 2 possibile scenarios:
    /// A - GatedOperation is not run in a queue.
    /// B - GatdOperation is run in a queue.
    /// For both of them, is the gate is closed, both the GateOpeation and its undelrying operation will be marked as cancelled.
    
    /// (A) if the GatedOperation is not added to a queue, the condition will be evaluated internally.
    operation.addCondition(condition)
    
    super.init(operation: operation, exclusivityManager: exclusivityManager,underlyingQueue: underlyingQueue)
    
    /// (A) If the operation is being evaluated internally, in case of failure the GatedOperation will be marked as cancelled.
    operation.addObserver(DidFinishConditionsEvaluationObserver(closure: { [weak self] (operation, errors) in
      if !errors.isEmpty {
        self?.requiresCancellationBeforeFinishing = true
      }
    }))
    
    /// (B) If the gate is closed and the GatedOperation is being run on a queue, this observer will flag the undelrying operation as cancelled (for consistency).
    addObserver(DidFinishConditionsEvaluationObserver(closure: { [weak self] (operation, errors) in
      if !errors.isEmpty {
        assert(self === operation)
        if let this = operation as? GatedOperation {
          this.operation.cancel(errors: errors)
          this.operation.finish()
        }
      }
    }))
    
    addCondition(BlockCondition(block: gate))
    
    name = "GatedOperation <\(operation.operationName)>"
  }
}

private struct DidFinishConditionsEvaluationObserver: OperationDidFinishConditionsEvaluationsObserving {
  private let closure: (AdvancedOperation, [Error]) -> Void
  
  init(closure: @escaping (AdvancedOperation, [Error]) -> Void) {
    self.closure = closure
  }
  
  func operationDidFailConditionsEvaluations(operation: AdvancedOperation, withErrors errors: [Error]) {
    closure(operation, errors)
  }
}
