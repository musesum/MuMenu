// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MuMenu",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MuMenu", targets: ["MuMenu"])],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", branch: "sync"),
        .package(url: "https://github.com/musesum/MuVision.git", branch: "sync"),
        .package(url: "https://github.com/musesum/MuPeer.git", branch: "sync"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuVision", package: "MuVision"),
                .product(name: "MuPeer", package: "MuPeer"),
                ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
