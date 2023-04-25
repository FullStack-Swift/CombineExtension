// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CombineExtension",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "CombineExtension",
      targets: ["CombineExtension"]),
  ],
  dependencies: [
    
  ],
  targets: [
    .target(
      name: "CombineExtension",
      dependencies: []),
    .testTarget(
      name: "CombineExtensionTests",
      dependencies: ["CombineExtension"]),
  ]
)
