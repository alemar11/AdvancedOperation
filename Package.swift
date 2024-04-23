// swift-tools-version:5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
  name: "AdvancedOperation",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v5), .visionOS(.v1)],
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources", swiftSettings: swiftSettings),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"], swiftSettings: swiftSettings)
  ],
  swiftLanguageVersions: [.v5]
)
