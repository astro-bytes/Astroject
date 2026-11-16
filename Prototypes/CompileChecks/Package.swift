// swift-tools-version: 6.2
// Prototype only. Each target here except `Allowed` is meant to fail to compile.
// check.sh builds each one and checks that it fails, and prints the compiler's error.

import PackageDescription

let mainActorByDefault: [SwiftSetting] = [.defaultIsolation(MainActor.self)]
let dependency: [Target.Dependency] = [.product(name: "AstrojectUnified", package: "UnifiedContainer")]

let package = Package(
    name: "CompileChecks",
    platforms: [.iOS(.v18), .macOS(.v15), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)],
    dependencies: [.package(path: "../UnifiedContainer")],
    targets: [
        // Must compile: the safe versions of the code below.
        .target(name: "Allowed", dependencies: dependency, swiftSettings: mainActorByDefault),
        // Must not compile.
        .target(name: "ReadsMainActorState", dependencies: dependency, swiftSettings: mainActorByDefault),
        .target(name: "BuildsMainActorType", dependencies: dependency, swiftSettings: mainActorByDefault),
        .target(name: "CapturesNonSendable", dependencies: dependency)
    ]
)
