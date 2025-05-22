// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Astroject",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        // Libraries for the Astroject framework
        .library(name: "Astroject",           targets: ["AstrojectCore"]),
        .library(name: "Astroject-Async",     targets: ["AstrojectCore", "Async"]),
        .library(name: "Astroject-Sync",      targets: ["AstrojectCore", "Sync"]),
        .library(name: "Astroject-Nexus",     targets: ["Nexus"]),
        .library(name: "Astroject-Singularity", targets: ["Singularity"])
    ],
    dependencies: [
        // Development dependency for linting
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.58.2")
    ],
    targets: [
        // Core framework targets
        .target(
            name: "AstrojectCore",
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Async",
            dependencies: ["AstrojectCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Mocks",
            dependencies: ["AstrojectCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Nexus",
            dependencies: ["AstrojectCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Singularity",
            dependencies: ["AstrojectCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .target(
            name: "Sync",
            dependencies: ["AstrojectCore"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),

        // Test targets for each framework component
        .testTarget(
            name: "AsyncTests",
            dependencies: ["AstrojectCore", "Async", "Mocks"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["AstrojectCore", "Mocks"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "NexusTests",
            dependencies: ["Nexus"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SingularityTests",
            dependencies: ["Singularity"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SyncTests",
            dependencies: ["AstrojectCore", "Sync", "Mocks"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        )
    ]
)
