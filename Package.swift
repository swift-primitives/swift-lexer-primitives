// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-lexer",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Lexer",
            targets: ["Lexer"]
        ),
        .library(
            name: "Lexer Standard Library Integration",
            targets: ["Lexer Standard Library Integration"]
        ),
        .library(
            name: "Lexer Apple Foundation Integration",
            targets: ["Lexer Apple Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-token.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-cursor.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-cursor.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-span.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-text.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-affine.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Lexer",
            dependencies: [
                .product(name: "Token", package: "swift-token"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(
                    name: "Memory Cursor",
                    package: "swift-memory-cursor"
                ),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Span", package: "swift-span"),
                .product(name: "Text", package: "swift-text"),
                .product(name: "Affine", package: "swift-affine"),
            ]
        ),
        .target(
            name: "Lexer Standard Library Integration",
            dependencies: ["Lexer"]
        ),
        .target(
            name: "Lexer Apple Foundation Integration",
            dependencies: [
                "Lexer",
                "Lexer Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Lexer Tests",
            dependencies: [
                "Lexer"
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
