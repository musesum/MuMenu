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
        .package(url: "https://github.com/musesum/MuPar.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuFlo.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuTime.git", from: "0.23.0"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuPar", package: "MuPar"),
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuTime", package: "MuTime")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
