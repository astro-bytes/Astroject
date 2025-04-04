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
        .library(name: "Astroject", targets: ["AstrojectCore"]),
        .library(name: "Astroject-Nexus", targets: ["Nexus"]),
        .library(name: "Astroject-Singularity", targets: ["Singularity"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.58.2") // Add SwiftLint as a development dependency
    ],
    targets: [
        .target(name: "AstrojectCore", plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(name: "Nexus", dependencies: ["AstrojectCore"], plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
        .target(name: "Singularity", dependencies: ["AstrojectCore"], plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),

        .testTarget(name: "CoreTests", dependencies: ["AstrojectCore"]),
        .testTarget(name: "NexusTests", dependencies: ["Nexus"]),
        .testTarget(name: "SingularityTests", dependencies: ["Singularity"]),
    ]
)
