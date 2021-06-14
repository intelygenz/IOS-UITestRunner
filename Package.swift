// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UITestRunner",
    products: [
        .library(
            name: "UITestRunner",
            targets: ["UITestRunner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/intelygenz/IOS-GherkParser", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "UITestRunner",
            dependencies: ["IOS-GherkParser"]),
        .testTarget(
            name: "UITestRunnerTests",
            dependencies: ["UITestRunner"]),
    ]
)
