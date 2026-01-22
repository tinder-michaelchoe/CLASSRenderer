// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScalsTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Shared library with common utilities
        .library(
            name: "ScalsToolsCore",
            targets: ["ScalsToolsCore"]
        ),
        // Individual CLI tools
        .executable(name: "scals-component-generator", targets: ["ComponentGenerator"]),
        .executable(name: "scals-property-validator", targets: ["PropertyValidator"]),
        .executable(name: "scals-migration-assistant", targets: ["MigrationAssistant"]),
        .executable(name: "scals-test-generator", targets: ["TestGenerator"]),
        .executable(name: "scals-integration-test-generator", targets: ["IntegrationTestGenerator"]),
        .executable(name: "scals-reference-generator", targets: ["ReferenceGenerator"]),
        .executable(name: "scals-consistency-checker", targets: ["ConsistencyChecker"]),
        .executable(name: "scals-performance-profiler", targets: ["PerformanceProfiler"]),
        .executable(name: "scals-action-generator", targets: ["ActionGenerator"]),
        .executable(name: "scals-design-system-generator", targets: ["DesignSystemGenerator"]),
        .executable(name: "scals-custom-component-generator", targets: ["CustomComponentGenerator"]),
        .executable(name: "scals-update-assistant", targets: ["UpdateAssistant"]),
    ],
    dependencies: [
        // Swift Argument Parser for CLI argument handling
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        // Stencil for template-based code generation
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.0"),
        // SwiftSyntax for AST parsing and code analysis
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        // MARK: - Shared Core Library
        .target(
            name: "ScalsToolsCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Stencil",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/ScalsToolsCore"
        ),

        // MARK: - Tool Executables

        // 1.1 Component Generator
        .executableTarget(
            name: "ComponentGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/ComponentGenerator"
        ),

        // 1.2 Component Property Validator
        .executableTarget(
            name: "PropertyValidator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/PropertyValidator"
        ),

        // 1.3 Component Migration Assistant
        .executableTarget(
            name: "MigrationAssistant",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/MigrationAssistant"
        ),

        // 2.1 Test Case Generator from Schema
        .executableTarget(
            name: "TestGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/TestGenerator"
        ),

        // 2.3 Integration Test Generator
        .executableTarget(
            name: "IntegrationTestGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/IntegrationTestGenerator"
        ),

        // 3.1 Component Reference Generator
        .executableTarget(
            name: "ReferenceGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/ReferenceGenerator"
        ),

        // 4.1 Component Consistency Checker
        .executableTarget(
            name: "ConsistencyChecker",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/ConsistencyChecker"
        ),

        // 4.4 Performance Profiler
        .executableTarget(
            name: "PerformanceProfiler",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/PerformanceProfiler"
        ),

        // 6.1 Action Handler Generator
        .executableTarget(
            name: "ActionGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/ActionGenerator"
        ),

        // 6.2 Design System Provider Generator
        .executableTarget(
            name: "DesignSystemGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/DesignSystemGenerator"
        ),

        // 6.4 Custom Component Template Generator
        .executableTarget(
            name: "CustomComponentGenerator",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/CustomComponentGenerator"
        ),

        // 7.2 Component Update Assistant
        .executableTarget(
            name: "UpdateAssistant",
            dependencies: [
                "ScalsToolsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/UpdateAssistant"
        )
    ]
)
