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
import os.log

@available(iOS 11, tvOS 11, macOS 10.12, watchOS 4.0, *)
public final class OSLogObserver: OperationObserving {
  private let log: OSLog

  init(log: OSLog = .default) {
    self.log = log
  }

  private func nameForOperation(_ operation: Operation) -> String {
    return operation.name ?? "\(type(of: operation))"
  }

  public func operationWillExecute(operation: Operation) {
    os_log("%{public}s has started.", log: log, type: .default, nameForOperation(operation))
  }

  public func operationWillFinish(operation: Operation, withErrors errors: [Error]) {
    os_log("%{public}s is finishing.", log: log, type: .default, nameForOperation(operation))
  }

  public func operationDidFinish(operation: Operation, withErrors errors: [Error]) {
    let name = nameForOperation(operation)

    if errors.isEmpty {
      os_log("%{public}s has finished.", log: log, type: .default, name)
    } else {
      os_log("%{public}s has finished with errors: %@", log: log, type: .error, nameForOperation(operation), errors)
    }
  }

  public func operationWillCancel(operation: Operation, withErrors errors: [Error]) {
    os_log("%{public}s is cancelling.", log: log, type: .default, nameForOperation(operation))
  }

  public func operationDidCancel(operation: Operation, withErrors errors: [Error]) {
    let name = nameForOperation(operation)

    if errors.isEmpty {
      os_log("%{public}s has been cancelled.", log: log, type: .default, name)
    } else {
      os_log("%{public}s has been cancelled with errors: %@", log: log, type: .error, name, errors)
    }
  }

  public func operation(operation: Operation, didProduce producedOperation: Operation) {
    os_log("%{public}s has produced a new operation: %{public}s.", log: log, type: .default, nameForOperation(operation), nameForOperation(producedOperation))
  }

}

extension AdvancedOperation {

  @available(iOS 11, tvOS 11, macOS 10.12, watchOS 4.0, *)
  public func enableLog(log: OSLog) {
    let observer = OSLogObserver(log: log)
    addObserver(observer)
  }

  // log stream --level debug --predicate 'subsystem contains "org.tinrobots.AdvancedOperation"'
  @available(iOS 11, tvOS 11, macOS 10.12, watchOS 4.0, *)
  public func enableLog() {
    let log = OSLog(subsystem: identifier, category: "AdvancedOperation")
    enableLog(log: log)
  }

}
