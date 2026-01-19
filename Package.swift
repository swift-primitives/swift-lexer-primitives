// swift-tools-version: 6.2

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
        )
    ],
    dependencies: [
        .package(path: "../swift-token-primitives"),
        .package(path: "../swift-source-primitives")
    ],
    targets: [
        .target(
            name: "Lexer Primitives",
            dependencies: [
                .product(name: "Token Primitives", package: "swift-token-primitives"),
                .product(name: "Source Primitives", package: "swift-source-primitives")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety()
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
