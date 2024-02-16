// swift-tools-version: 5.8

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
        .package(url: "https://github.com/musesum/MuExtensions.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuHand.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuFlo.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuMetal.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuPeer.git", from: "0.23.0"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuMetal", package: "MuMetal"),
                .product(name: "MuPeer", package: "MuPeer"),
                .product(name: "MuHand", package: "MuHand"),
                .product(name: "MuExtensions", package: "MuExtensions")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
