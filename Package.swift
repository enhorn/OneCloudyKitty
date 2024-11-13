// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OneCloudyKitty",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "OneCloudyKitty", targets: ["OneCloudyKitty"])
    ],
    targets: [
        .target(name: "OneCloudyKitty"),
        .testTarget(
            name: "OneCloudyKittyTests",
            dependencies: ["OneCloudyKitty"]
        ),
    ]
)
