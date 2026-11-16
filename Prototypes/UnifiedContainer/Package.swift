// swift-tools-version: 6.2
// Prototype only: one container with a sync graph and async setup.
// Not part of the Astroject package. See README.md in this folder.

import PackageDescription

let package = Package(
    name: "UnifiedContainer",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "AstrojectUnified", targets: ["AstrojectUnified"])
    ],
    targets: [
        .target(name: "AstrojectUnified"),
        .testTarget(
            name: "AstrojectUnifiedTests",
            dependencies: ["AstrojectUnified"]
        ),
        // Same kind of app code, compiled the way a new Xcode 26 app target is:
        // everything is @MainActor unless it says otherwise.
        .testTarget(
            name: "DefaultMainActorTests",
            dependencies: ["AstrojectUnified"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
