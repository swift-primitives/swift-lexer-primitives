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
            name: "Lexer Test Support",
            targets: ["Lexer Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-token.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-cursor.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-memory-cursor.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-memory.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-byte.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-span.git",
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
                .product(name: "Cursor Primitive", package: "swift-cursor"),
                .product(
                    name: "Memory Cursor",
                    package: "swift-memory-cursor"
                ),
                .product(name: "Memory Primitive", package: "swift-memory"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Span Protocol", package: "swift-span"),
            ]
        ),
        .target(
            name: "Lexer Test Support",
            dependencies: [
                "Lexer",
                .product(name: "Token Test Support", package: "swift-token"),
            ],
            path: "Tests/Support"
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
