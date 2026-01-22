// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScalsWasm",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "ScalsWasm",
            targets: ["ScalsWasm"]
        ),
    ],
    dependencies: [
        // No external dependencies - using local SCALS module
    ],
    targets: [
        // SCALS core library
        .target(
            name: "SCALS",
            path: "SCALS",
            exclude: [
                // SwiftUI/UIKit renderers
                "Renderers/SwiftUI",
                "Renderers/UIKit",
                "Renderers/ScalsUIKitView.swift",
                "Renderers/DebugRenderer.swift",
                "Renderers/UIKitRenderer.swift",
                "Rendering",
                // Extensibility (all depends on SwiftUI/UIKit)
                "Extensibility",
                // Lifecycle modifier (depends on SwiftUI)
                "Lifecycle/LifecycleModifier.swift"
            ],
            swiftSettings: [
                .swiftLanguageVersion(.v5),
                .unsafeFlags([
                    "-Xfrontend", "-disable-availability-checking",
                    "-Xfrontend", "-assume-single-threaded"
                ])
            ]
        ),
        // ScalsResolvers module (component and layout resolvers)
        .target(
            name: "ScalsResolvers",
            dependencies: ["SCALS"],
            path: "ScalsModules",
            exclude: [
                "ComponentResolvers/PageIndicatorComponentResolver.swift"
            ],
            sources: [
                "ComponentResolvers",
                "SectionLayoutResolvers",
                "Extensions/SectionLayoutConfigResolverRegistry+Default.swift",
                "Extensions/Document+ComponentKind.swift"
            ],
            swiftSettings: [
                .swiftLanguageVersion(.v5),
                .unsafeFlags([
                    "-Xfrontend", "-disable-availability-checking",
                    "-Xfrontend", "-assume-single-threaded"
                ])
            ]
        ),
        // Main executable
        .executableTarget(
            name: "ScalsWasm",
            dependencies: [
                "SCALS",
                "ScalsResolvers"
            ],
            path: "Sources/ScalsWasm",
            swiftSettings: [
                .swiftLanguageVersion(.v5),
                .unsafeFlags([
                    "-Xfrontend", "-disable-availability-checking",
                    "-Xfrontend", "-assume-single-threaded"
                ])
            ]
        ),
    ]
)
