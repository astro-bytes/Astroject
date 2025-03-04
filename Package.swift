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
        .library(name: "Astroject", targets: ["Astroject"]),
        .library(name: "AstrojectSingularity", targets: ["Singularity"]),
        .library(name: "AstrojectNexus", targets: ["Nexus"])
    ],
    targets: [
        .target(name: "Astroject"),
        .target(name: "Singularity", dependencies: ["Astroject"]),
        .target(name: "Nexus", dependencies: ["Astroject"]),
        
        .testTarget(name: "AstrojectTests", dependencies: ["Astroject"]),
    ]
)
