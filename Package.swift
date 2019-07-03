// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "AdvancedOperation",
  platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)],
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources"),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"])
  ],
  swiftLanguageVersions: [.v5]
)
