// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AdvancedOperation",
  products: [
    .library(name: "AdvancedOperation", targets: ["AdvancedOperation"])
  ],
  targets: [
    .target(name: "AdvancedOperation", path: "Sources"),
    .testTarget(name: "AdvancedOperationTests", dependencies: ["AdvancedOperation"])
  ],
  swiftLanguageVersions: [.v5]
)
