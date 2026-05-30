// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MuMenu",
    platforms: [.iOS(.v17), .visionOS(.v2), .watchOS(.v10)],
    products: [.library(name: "MuMenu", targets: ["MuMenu"])],
    dependencies: [
        // DEV: local paths during watchOS port. Restore github URLs before publish.
        .package(name: "MuFlo", path: "../MuFlo"),
        .package(name: "MuVision", path: "../MuVision"),
        .package(name: "MuPeers", path: "../MuPeers"),
        .package(name: "MuHands", path: "../MuHands"),
    ],
    targets: [
        .target(
            name: "MuMenu",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
                .product(name: "MuVision", package: "MuVision",
                         condition: .when(platforms: [.iOS, .visionOS])),
                .product(name: "MuPeers", package: "MuPeers",
                         condition: .when(platforms: [.iOS, .visionOS, .watchOS])),
                .product(name: "MuHands", package: "MuHands",
                         condition: .when(platforms: [.iOS, .visionOS])),
                ],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MuMenuTests",
            dependencies: ["MuMenu"]),
    ]
)
