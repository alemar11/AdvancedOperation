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

/// An `AdvancedOperation` that will simply wait for a given time interval, or until a specific `Date`.
/// If the interval is negative, or the `Date` is in the past, then this operation immediately finishes.
/// - Note: A `DelayOperation` cannot be cancelled once started running.
public final class DelayOperation: AdvancedOperation {

  // MARK: - Properties

  private let delay: Delay
  private let queue: DispatchQueue

  // MARK: - Delay Types

  private enum Delay {
    case interval(TimeInterval)
    case date(Date)

    /// Returns the delay in seconds.
    var seconds: TimeInterval {
      let interval: TimeInterval

      switch self {
      case .interval(let seconds):
        interval = seconds

      case .date(let date):
        interval = date.timeIntervalSinceNow
      }
      return interval
    }
  }

  // MARK: - Initialization

  public init(interval: TimeInterval, queue: DispatchQueue = .global(qos: .default)) {
    self.delay = .interval(interval)
    self.queue = queue

    super.init()

    name = "DelayOperation <\(delay)>"
  }

  public init(until date: Date, queue: DispatchQueue = .global(qos: .default)) {
    self.delay = .date(date)
    self.queue = queue

    super.init()
  }

  // MARK: - Methods

  public override func main() {
    guard delay.seconds > 0 else { finish(); return }

    queue.asyncAfter(deadline: .now() + delay.seconds) { [weak self] in
      guard let self = self else {
        return
      }

      self.finish()
    }

  }

}
