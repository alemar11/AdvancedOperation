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

#if !os(Linux)

import Foundation

  public class OperationObserverController {
    let operation: Operation

    private(set) var observers = [OperationObserving]()
    private var keyValueObservers = [NSKeyValueObservation]()

    public convenience init(operation: Operation, observers: OperationObserving...) {
      self.init(operation: operation)

      for observer in observers {
        self.registerObserver(observer)
      }
    }

    public init(operation: Operation) {
      self.operation = operation
      self.setup()
    }

    private func setup() {

      /// isExecuting KVO
      let isExecuting = operation.observe(\.isExecuting, options: [.old, .new]) { [weak self] (operation, change) in
        guard let `self` = self else { return }
        guard let old = change.oldValue else { return }
        guard let new = change.newValue else { return }
//
        if (old == false && new == true) {
          for observer in self.observers {
            observer.operationDidStart(operation: operation)
          }
        }

//        else if operation.isCancelled && old == false && new == false {
//          for observer in self.observers {
//            observer.operationDidStart(operation: operation)
//          }
//        } else {
//          print(operation)
//          print("")
//        }

//        guard let old = change.oldValue, old == false else { return }
//        guard let new = change.newValue, new == true else { return }
//
//        for observer in self.observers {
//          observer.operationWillPerform(operation: operation)
//        }



      }

      /// isFinished KVO
      let isFinished = operation.observe(\.isFinished, options: [.old, .new]) { [weak self] (operation, change) in
        guard let `self` = self else { return }
        guard let old = change.oldValue, old == false else { return }
        guard let new = change.newValue, new == true else { return }

        // collects errors if it's an AdvancedOperation
        var errors = [Error]()
        if let advancedOperation = operation as? AdvancedOperation {
          errors = advancedOperation.errors
        }

        for observer in self.observers {
          observer.operationDidFinish(operation: operation, withErrors: errors)
        }

      }

      /// isCancelled KVO
      let isCancelled = operation.observe(\.isCancelled, options: [.prior, .old, .new]) { [weak self] (operation, change) in
        guard let `self` = self else { return }
        guard let old = change.oldValue, old == false else { return }

        var errors = [Error]()
        if let advancedOperation = operation as? AdvancedOperation {
          errors = advancedOperation.errors
        }

        if change.isPrior {
          for observer in self.observers {
            observer.operationWillCancel(operation: self.operation, withErrors: errors)
          }

        } else {
          guard let new = change.newValue, new == true else { return }

          for observer in self.observers {
            observer.operationDidCancel(operation: self.operation, withErrors: errors)
          }
        }

      }

      keyValueObservers.append(contentsOf: [isExecuting, isFinished, isCancelled])
    }

    /// Registers a given observer.
    public func registerObserver(_ observer: OperationObserving) {
      observers.append(observer)
    }

    /// Removes all regisitered observers.
    public func removeAllObservers() {
      observers.removeAll()
    }

    /// Removes an observer with a specified `identifier`.
    public func removeObserver(withIdentifier identifier: String) {
      for (index, observer) in observers.enumerated() {
        if observer.identifier == identifier {
          observers.remove(at: index)
        }
      }
    }

  }

#endif

//TODO:
/// OperationQueue

/**
 The NSOperationQueue class is key-value coding (KVC) and key-value observing (KVO) compliant. You can observe these properties as desired to control other parts of your application. To observe the properties, use the following key paths::
 operations - read-only
 operationCount - read-only
 maxConcurrentOperationCount - readable and writable
 suspended - readable and writable
 name - readable and writable
 **/
