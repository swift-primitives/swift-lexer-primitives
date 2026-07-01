// swift-tools-version: 6.3.1

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
        .package(url: "https://github.com/swift-primitives/swift-token-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ascii-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-cursor-primitives.git", branch: "main"),
        // W3 PRUNE: path-dep every CHANGED package lexer needs (directly or
        // transitively). `Cursor<Text>(span)` now uses the cursor base init
        // (Text.Borrowed == Swift.Span<Byte>); the deleted byte-cursor
        // convenience init is no longer referenced. `text` is path-dep'd as a
        // transitive override (lexer → token → text) so its identity unifies
        // with the W3 version under SwiftPM's root-local-override (Finding 7).
        .package(url: "https://github.com/swift-primitives/swift-memory-cursor-primitives.git", branch: "main"),
        // Direct dep so Lexer.Scanner.swift can import Memory_Primitive for the
        // `Memory` namespace (was reached transitively via a now-deleted
        // re-export).
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
        // W3 PRUNE: direct dep so Lexer.Scanner.swift can import
        // Span_Protocol_Primitives for the Swift.Span: Span.`Protocol`
        // conformance (Finding 3/8).
        .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Lexer Primitives",
            dependencies: [
                .product(name: "Token Primitives", package: "swift-token-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
                .product(name: "Cursor Primitives", package: "swift-cursor-primitives"),
                .product(name: "Cursor Primitive", package: "swift-cursor-primitives"),
                .product(name: "Memory Cursor Primitives", package: "swift-memory-cursor-primitives"),
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Byte Primitives", package: "swift-byte-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
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
