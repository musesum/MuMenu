// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MuMenu",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MuMenu",
            targets: ["MuMenu"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/Par.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "Par", package: "Par")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
