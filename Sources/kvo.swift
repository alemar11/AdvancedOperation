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

/*
 private lazy var stateObservers: [NSKeyValueObservation] = {
 //TODO: add the prior value and check if it's different from new
 
 let cancelObserver = observe(\.isCancelled, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let cancelled = change.newValue else { return }
 
 if cancelled {
 for observer in self.observers {
 observer.operationDidCancel(operation: self, errors: self.errors)
 }
 }
 }
 
 let executeObserver = observe(\.isExecuting, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let executed = change.newValue else { return }
 
 if executed {
 for observer in self.observers {
 observer.operationDidStart(operation: self)
 }
 }
 }
 
 let finishObserver = observe(\.isFinished, options: .new) { [weak self] (operation, change) in
 guard let `self` = self else { return }
 guard let finished = change.newValue else { return }
 
 if finished {
 for observer in self.observers {
 observer.operationDidFinish(operation: self, errors: self.errors)
 }
 }
 }
 
 return [cancelObserver, executeObserver, finishObserver]
 }()
 */
