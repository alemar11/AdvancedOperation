//AdvancedOperation

import XCTest

extension XCTestCase {
  /// Checks for the callback to be the expected value within the given timeout.
  ///
  /// - Parameters:
  ///   - condition: The condition to be evaluated.
  ///   - timeout: The timeout in which the callback should return true.
  ///   - description: An optional description of a failure.
  func wait(for condition: @autoclosure @escaping () -> Bool, timeout: TimeInterval, description: String?, file: StaticString = #file, line: UInt = #line) {
    let end = Date().addingTimeInterval(timeout)
    var value: Bool = false
    let closure: () -> Void = { value = condition() }

    while !value && 0 < end.timeIntervalSinceNow {
      if RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.002)) {
        Thread.sleep(forTimeInterval: 0.002)
      }
      closure()
    }

    closure()

    let message = description ?? "Timed out waiting for condition to be true"
    XCTAssertTrue(value, message, file: file, line: line)
  }
}
