// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swift-lexer-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Lexer Primitives",
            targets: ["Lexer Primitives"]
        ),
        .library(
            name: "Lexer Primitives Test Support",
            targets: ["Lexer Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-token-primitives"),
        .package(path: "../swift-ascii-primitives"),
    ],
    targets: [
        .target(
            name: "Lexer Primitives",
            dependencies: [
                .product(name: "Token Primitives", package: "swift-token-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),
        .target(
            name: "Lexer Primitives Test Support",
            dependencies: [
                "Lexer Primitives",
                .product(name: "Token Primitives Test Support", package: "swift-token-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Lexer Primitives Tests",
            dependencies: [
                "Lexer Primitives",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
