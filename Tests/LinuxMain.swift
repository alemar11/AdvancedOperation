import XCTest
@testable import AdvancedOperationTests

XCTMain([
  testCase(AdvancedOperationTests.allTests),
  testCase(DelayOperationTests.allTests)
  ])
