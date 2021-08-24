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
        .package(name: "GherkParser", url: "https://github.com/intelygenz/IOS-GherkParser", .exact("0.5.6"))
    ],
    targets: [
        .target(
            name: "UITestRunner",
            dependencies: ["GherkParser"]),
        .testTarget(
            name: "UITestRunnerTests",
            dependencies: ["UITestRunner"]),
    ]
)
