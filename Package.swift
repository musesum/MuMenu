// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MuMenu",
    platforms: [.iOS(.v17), .visionOS(.v2)],
    products: [.library(name: "MuMenu", targets: ["MuMenu"])],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", branch: "main"),
        .package(url: "https://github.com/musesum/MuVision.git", branch: "main"),
        .package(url: "https://github.com/musesum/MuPeers.git", branch: "main"),
        .package(url: "https://github.com/musesum/MuHands.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuVision", package: "MuVision"),
                .product(name: "MuPeers", package: "MuPeers"),
                .product(name: "MuHands", package: "MuHands"),
                ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
