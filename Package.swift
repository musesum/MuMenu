// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MuMenu",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MuMenu", targets: ["MuMenu"])],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", branch: "main"),
        .package(url: "https://github.com/musesum/MuVision.git", branch: "main"),
        .package(url: "https://github.com/musesum/MuPeers.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuVision", package: "MuVision"),
                .product(name: "MuPeers", package: "MuPeers"),
                ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
