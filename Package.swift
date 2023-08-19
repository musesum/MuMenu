// swift-tools-version: 5.7

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
        .package(url: "https://github.com/musesum/MuPar.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuFlo.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuVisit.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuMetal.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuTime.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuPeer.git", from: "0.23.0"), // TextureData
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuPar", package: "MuPar"),
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuVisit", package: "MuVisit"),
                .product(name: "MuMetal", package: "MuMetal"),
                .product(name: "MuTime", package: "MuTime"),
                .product(name: "MuPeer", package: "MuPeer")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
