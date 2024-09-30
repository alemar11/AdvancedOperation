// swift-tools-version: 6.0

import PackageDescription
import Foundation

let buildingDocumentation = getenv("BUILDING_FOR_DOCUMENTATION_GENERATION") != nil

let swiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("StrictConcurrency"),
  .swiftLanguageMode(.v6)
]

let package = Package(
  name: "AdvancedOperation",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources", swiftSettings: swiftSettings),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"], swiftSettings: swiftSettings)
  ],
  swiftLanguageModes: [.v5]
)

// Only require the docc plugin when building documentation
package.dependencies += buildingDocumentation ? [
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
] : []
