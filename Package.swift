// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "AdvancedOperation",
  platforms: [.macOS(.v10_13), .iOS(.v11), .tvOS(.v11), .watchOS(.v4)],
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources"),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"])
  ],
  swiftLanguageVersions: [.v5]
)
