import XCTest
@testable import AdvancedOperationTests

XCTMain([
  testCase(AdvancedOperationTests.allTests),
  testCase(DelayOperationTests.allTests),
  //testCase(AdvancedOperationQueueTests.allTests), // OperationQueue on Linux has still bugs, checks LinuxBehaviorsTests.
  testCase(LinuxBehaviorsTests.allTests)
  ])
