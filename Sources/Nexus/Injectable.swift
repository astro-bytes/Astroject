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

// MARK: - Support for generated code

public extension Container {
    /// Registers a product from two closures, and uses the one that fits the container's `ResolutionMode`.
    ///
    /// `@Injectable` generates calls to this when the initializer has `@Named` or `@Argument`
    /// parameters, because those are resolved explicitly rather than by type alone.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name for the registration.
    ///   - resolveSync: Creates the product for a `.sync` container, or `nil` when it can only be
    ///     created asynchronously.
    ///   - resolveAsync: Creates the product for an `.async` container.
    ///   - fileID: The file the registration is made from, for the registration report. Defaults to `#fileID`.
    ///   - line: The line the registration is made from, for the registration report. Defaults to `#line`.
    /// - Returns: The registration, for further configuration.
    /// - Throws: `AstrojectError.invalidFactory` if the container is `.sync` and `resolveSync` is `nil`.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        resolveSync: ((Resolver) throws -> Product)?,
        resolveAsync: @escaping (Resolver) async throws -> Product,
        fileID: String = #fileID,
        line: UInt = #line
    ) throws -> any Registrable<Product> {
        let factory: Factory<Product, Resolver>
        switch resolutionMode {
        case .sync:
            guard let resolveSync else { throw AstrojectError.invalidFactory }
            factory = Factory(.sync(resolveSync))
        case .async:
            factory = Factory(.async(resolveAsync))
        }
        return try register(productType, name: name, factory: factory, fileID: fileID, line: line)
    }
}

/// Resolves an `@Injectable` initializer parameter by name.
///
/// Swift macros can't attach to parameters, so `@Named` is a property wrapper that does nothing
/// at runtime: callers still pass a plain value. `@Injectable` reads it and resolves the
/// parameter with `resolve(_:name:)`.
///
/// ```swift
/// @Injectable
/// final class AnalyticsService {
///     init(@Named("analytics") logger: Logger, session: URLSession) { ... }
/// }
/// ```
@propertyWrapper
public struct Named<Value> {
    public var wrappedValue: Value
    /// The registration name the parameter is resolved with.
    public let name: String
    
    /// - Parameters:
    ///   - wrappedValue: The parameter's value.
    ///   - name: The registration name to resolve the parameter with.
    public init(wrappedValue: Value, _ name: String) {
        self.wrappedValue = wrappedValue
        self.name = name
    }
}

/// Marks an `@Injectable` initializer parameter as a runtime value.
///
/// A type with `@Argument` parameters isn't registered itself. `@Injectable` generates a nested
/// `Factory` with a `make(…)` method that takes the `@Argument` values and resolves everything
/// else, and registers the factory. Like `@Named`, it does nothing at runtime.
///
/// ```swift
/// @Injectable
/// final class PuzzleDetailViewModel {
///     init(@Argument puzzleID: String, repository: PuzzleRepository) { ... }
/// }
///
/// let factory = try container.resolve(PuzzleDetailViewModel.Factory.self)
/// let viewModel = try factory.make(puzzleID: "42")
/// ```
@propertyWrapper
public struct Argument<Value> {
    public var wrappedValue: Value
    
    /// - Parameter wrappedValue: The parameter's value.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
