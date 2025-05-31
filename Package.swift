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
        .library(name: "Astroject", targets: ["AstrojectCore"]),
        .library(name: "Astroject-Async", targets: ["AstrojectCore", "AstrojectAsync"]),
        .library(name: "Astroject-Sync", targets: ["AstrojectCore", "AstrojectSync"])
//        .library(name: "Astroject-Nexus", targets: ["Nexus"]),
//        .library(name: "Astroject-Singularity", targets: ["Singularity"])
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
//        .target(
//            name: "Nexus",
//            dependencies: ["AstrojectCore"],
//            path: "Sources/Nexus"
//        ),
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
//        .testTarget(
//            name: "NexusTests",
//            dependencies: ["Nexus"]
//        ),
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
