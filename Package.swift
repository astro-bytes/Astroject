// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .library(name: "Astroject", targets: ["AstrojectCore"]),
        .library(name: "Astroject-Async", targets: ["AstrojectCore", "AstrojectAsync"]),
        .library(name: "Astroject-Sync", targets: ["AstrojectCore", "AstrojectSync"]),
        .library(name: "Astroject-Nexus", targets: ["AstrojectCore", "AstrojectNexus"]),
        // Nexus macros. Only apps that use this product build swift-syntax.
        .library(name: "Astroject-NexusMacros", targets: ["AstrojectCore", "AstrojectNexus", "AstrojectNexusMacros"])
//        .library(name: "Astroject-Singularity", targets: ["Singularity"])
    ],
    dependencies: [
        // swift-syntax majors track the compiler (600 = Swift 6.0, 601 = 6.1, ...).
        // Accept any 6.x compiler's release.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"700.0.0")
    ],
    targets: [
        // Core framework targets
        .target(
            name: "AstrojectCore",
            path: "Sources/Core"
        ),
        .target(
            name: "AstrojectAsync",
            dependencies: ["AstrojectCore"],
            path: "Sources/Async"
        ),
        .target(
            name: "Mocks",
            dependencies: ["AstrojectCore"],
            path: "Sources/Mocks"
        ),
        .target(
            name: "AstrojectNexus",
            dependencies: ["AstrojectCore"],
            path: "Sources/Nexus"
        ),
        // The compiler plugin that implements the Nexus macros
        .macro(
            name: "AstrojectNexusMacrosPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/NexusMacrosPlugin"
        ),
        // The macro declarations apps import
        .target(
            name: "AstrojectNexusMacros",
            dependencies: ["AstrojectNexus", "AstrojectNexusMacrosPlugin"],
            path: "Sources/NexusMacros"
        ),
//        .target(
//            name: "Singularity",
//            dependencies: ["AstrojectCore"],
//            path: "Sources/Singularity"
//        ),
        .target(
            name: "AstrojectSync",
            dependencies: ["AstrojectCore"],
            path: "Sources/Sync"
        ),
        
        // Test targets for each framework component
        .testTarget(
            name: "AsyncTests",
            dependencies: ["AstrojectCore", "AstrojectAsync", "Mocks"],
            path: "Tests/AsyncTests"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["AstrojectCore", "Mocks"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "NexusMacrosTests",
            dependencies: [
                "AstrojectNexusMacrosPlugin",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Tests/NexusMacrosTests"
        ),
        .testTarget(
            name: "NexusMacrosRuntimeTests",
            dependencies: ["AstrojectNexusMacros", "AstrojectSync", "AstrojectAsync"],
            path: "Tests/NexusMacrosRuntimeTests"
        ),
        .testTarget(
            name: "NexusTests",
            dependencies: ["AstrojectCore", "AstrojectSync", "AstrojectAsync", "AstrojectNexus"],
            path: "Tests/NexusTests"
        ),
//        .testTarget(
//            name: "SingularityTests",
//            dependencies: ["Singularity"]
//        ),
        .testTarget(
            name: "SyncTests",
            dependencies: ["AstrojectCore", "AstrojectSync", "Mocks"],
            path: "Tests/SyncTests"
        )
    ]
)
