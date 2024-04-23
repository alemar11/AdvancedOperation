// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "AdvancedOperation",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v5)],
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources"),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"])
  ],
  swiftLanguageVersions: [.v5]
)
