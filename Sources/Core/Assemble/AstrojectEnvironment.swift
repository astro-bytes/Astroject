//
//  AstrojectEnvironment.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Foundation

/// How the app is running, used to pick which assemblies an `Assembler` runs.
///
/// Pass the environment to the container or assembler, and declare `environments` on an
/// `Assembly` to limit where it runs. The app decides the environment, because Astroject's
/// own `#if DEBUG` describes how the package was built, and a unit test run is also a debug build.
///
/// ```swift
/// struct DebugMenuAssembly: Assembly {
///     static var environments: Set<AstrojectEnvironment>? { [.debug] }
///     func assemble(container: Container) throws { ... }
/// }
///
/// #if DEBUG
/// let environment: AstrojectEnvironment = .debug
/// #else
/// let environment: AstrojectEnvironment = .release
/// #endif
/// let container = try SyncContainer(environment: environment, assemblies: [AppAssembly(), DebugMenuAssembly()])
/// ```
public enum AstrojectEnvironment: Hashable, Sendable, CustomStringConvertible {
    /// A debug build, run by a developer.
    case debug
    /// A release build, run by users.
    case release
    /// A test run, such as unit or UI tests.
    case test
    /// Any other environment, such as `.custom("staging")` or `.custom("preview")`.
    case custom(String)
    
    public var description: String {
        switch self {
        case .debug: "debug"
        case .release: "release"
        case .test: "test"
        case .custom(let name): name
        }
    }
}
