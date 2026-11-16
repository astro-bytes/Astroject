import Synchronization

/// Resolves dependencies. Sync only: there is no async `resolve`.
public protocol Resolver: Sendable {
    func resolve<Product>(_ type: Product.Type, name: String?) throws -> Product
}

public extension Resolver {
    func resolve<Product>(_ type: Product.Type) throws -> Product {
        try resolve(type, name: nil)
    }
}

/// Builds the graph from assemblies. Every factory is sync.
public protocol Assembly {
    func assemble(container: UnifiedContainer) throws
}

/// Adopted by assemblies that need to `await` before registering, for example to open
/// a database. `setUp` runs right before the assembly's own `assemble(container:)`.
public protocol AsyncSetup {
    func setUp(container: UnifiedContainer) async throws
}

/// One container for sync and async code: a sync graph with async setup.
///
/// Checked `Sendable`: its only stored property is a `Mutex`.
public final class UnifiedContainer: Resolver, Sendable {
    private let registrations = Mutex<[Key: Registration]>([:])

    public init() {}

    /// Builds the container synchronously.
    /// - Throws: `ContainerError.asyncSetupRequired` if any assembly adopts `AsyncSetup`.
    public init(assemblies: [any Assembly]) throws {
        let needsSetup = assemblies.filter { $0 is any AsyncSetup }
        guard needsSetup.isEmpty else {
            throw ContainerError.asyncSetupRequired(needsSetup.map { String(describing: type(of: $0)) })
        }
        for assembly in assemblies {
            try assembly.assemble(container: self)
        }
    }

    /// Builds the container, running each assembly's async setup first.
    public init(assemblies: [any Assembly]) async throws {
        for assembly in assemblies {
            if let setup = assembly as? any AsyncSetup {
                try await setup.setUp(container: self)
            }
            try assembly.assemble(container: self)
        }
    }

    // MARK: Register

    /// Registers a sync factory.
    @discardableResult
    public func register<Product>(
        _ type: Product.Type,
        name: String? = nil,
        factory: @escaping (any Resolver) throws -> Product
    ) -> RegistrationHandle {
        add(Registration(key: Key(type, name: name), kind: .sync { try factory($0) }))
    }

    /// Registers a finished value as a singleton. The usual way to hand setup results to the graph.
    @discardableResult
    public func register<Product>(
        _ type: Product.Type,
        name: String? = nil,
        instance: Product
    ) -> RegistrationHandle {
        let box = UncheckedBox(instance)
        return register(type, name: name) { _ in box.value }.asSingleton()
    }

    /// Registers a factory that must run on the main actor, such as a `@MainActor` view model.
    /// Resolve it with `container.main.resolve(_:)`.
    @discardableResult
    public func registerMainActor<Product>(
        _ type: Product.Type,
        name: String? = nil,
        factory: @escaping @MainActor (MainResolver) throws -> Product
    ) -> RegistrationHandle {
        add(Registration(key: Key(type, name: name), kind: .mainActor { @MainActor resolver in
            try factory(resolver)
        }))
    }

    // MARK: Resolve

    public func resolve<Product>(_ type: Product.Type, name: String?) throws -> Product {
        let registration = try registration(for: Key(type, name: name))
        let value: Any = try ResolutionPath.push(registration.key) {
            switch registration.kind {
            case .sync(let factory):
                return try registration.instance { try factory(self) }
            case .mainActor:
                // Thrown even if a singleton already exists, so the result never depends on timing.
                throw ContainerError.mainActorRequired(registration.key.description)
            case .providerMarker:
                throw ContainerError.registeredAsProvider(registration.key.description)
            }
        }
        return try cast(value, to: type, key: registration.key)
    }

    // MARK: Internals

    @discardableResult
    func add(_ registration: Registration) -> RegistrationHandle {
        registrations.withLock { $0[registration.key] = registration }
        return RegistrationHandle(registration: registration)
    }

    func registration(for key: Key) throws -> Registration {
        guard let registration = registrations.withLock({ $0[key] }) else {
            throw ContainerError.noRegistration(key.description)
        }
        return registration
    }

    func cast<Product>(_ value: Any, to type: Product.Type, key: Key) throws -> Product {
        guard let product = value as? Product else {
            throw ContainerError.typeMismatch(
                expected: key.description,
                actual: String(describing: Swift.type(of: value))
            )
        }
        return product
    }
}

/// Resolves on the main actor. It can run `registerMainActor` factories as well as sync ones.
///
/// This is a separate type, not a `@MainActor` overload of `resolve`, because Swift can't
/// overload two functions that differ only in isolation.
@MainActor
public struct MainResolver {
    let container: UnifiedContainer

    public func resolve<Product>(_ type: Product.Type, name: String? = nil) throws -> Product {
        let registration = try container.registration(for: Key(type, name: name))
        let value: Any = try ResolutionPath.push(registration.key) {
            switch registration.kind {
            case .sync(let factory):
                return try registration.instance { try factory(container) }
            case .mainActor(let factory):
                return try registration.instance { try factory(self) }
            case .providerMarker:
                throw ContainerError.registeredAsProvider(registration.key.description)
            }
        }
        return try container.cast(value, to: type, key: registration.key)
    }
}

public extension UnifiedContainer {
    /// A resolver for main-actor code, such as SwiftUI views.
    @MainActor
    var main: MainResolver { MainResolver(container: self) }
}
