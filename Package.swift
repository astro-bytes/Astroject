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
        .library(name: "Astroject", targets: ["Core"]),
        .library(name: "Astroject-Nexus", targets: ["Nexus"]),
        .library(name: "Astroject-Singularity", targets: ["Singularity"])
    ],
    targets: [
        .target(name: "Core"),
        .target(name: "Nexus", dependencies: ["Core"]),
        .target(name: "Singularity", dependencies: ["Core"]),
        
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "NexusTests", dependencies: ["Nexus"]),
        .testTarget(name: "SingularityTests", dependencies: ["Singularity"]),
    ]
)
