//
//  Injectable.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import AstrojectCore

/// A type that knows how to register itself with a container.
///
/// The `@Injectable` macro from `AstrojectNexusMacros` generates this conformance, registering
/// the type by its initializer. You can also conform by hand.
///
/// ```swift
/// @Injectable(scope: .singleton)
/// final class PuzzleRepository {
///     init(api: APIClient, logger: Logger) { ... }
/// }
///
/// try PuzzleRepository.register(in: container)
/// ```
public protocol Injectable {
    /// Registers this type with `container`.
    ///
    /// - Parameter container: The container to register with.
    static func register(in container: any Container) throws
}

public extension Container {
    /// Registers each `Injectable` type, in order.
    ///
    /// Registration is last one wins, so a later type replaces an earlier one registered for the same key.
    ///
    /// - Parameter injectables: The types to register.
    func register(injectables: [any Injectable.Type]) throws {
        for injectable in injectables {
            try injectable.register(in: self)
        }
    }
}

/// How a registration made by `@Injectable` manages its instances.
public enum InjectableScope: Sendable {
    /// A new instance for each resolution graph. This is the default.
    case graph
    /// One instance for the lifetime of the container.
    case singleton
    /// A new instance every time it is resolved.
    case transient
    /// One instance for as long as something else holds a strong reference to it.
    case weak
}
