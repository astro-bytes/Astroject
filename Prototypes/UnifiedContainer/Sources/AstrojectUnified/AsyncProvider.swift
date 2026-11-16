import Synchronization

/// A way to create a `Product` that needs `await`, handed out synchronously.
///
/// Sync code resolves `AsyncProvider<Product>` and awaits it later. Dependents hold the
/// provider, not the product, so async creation doesn't spread through the graph.
public struct AsyncProvider<Product>: Sendable {
    public typealias Make = @Sendable () async throws -> sending Product

    let make: Make

    /// Creates (or, for a singleton, returns) the product.
    public func callAsFunction() async throws -> sending Product {
        try await make()
    }
}

/// Returned by `registerProvider`, for setting the scope.
public struct ProviderHandle<Product>: Sendable {
    let source: ProviderSource<Product>
}

public extension ProviderHandle where Product: Sendable {
    /// Creates the product on the first `await`, then returns the same one.
    /// Concurrent first calls share one creation.
    ///
    /// Only available for `Sendable` products: one instance handed to many tasks has to be.
    @discardableResult
    func asSingleton() -> ProviderHandle {
        source.makeShared()
        return self
    }
}

public extension UnifiedContainer {
    /// Registers a type whose creation needs `await`, such as one with an `async init`.
    ///
    /// Resolve `AsyncProvider<Product>`; resolving `Product` itself throws
    /// `ContainerError.registeredAsProvider`.
    @discardableResult
    func registerProvider<Product>(
        _ type: Product.Type,
        name: String? = nil,
        factory: @escaping @Sendable (any Resolver) async throws -> sending Product
    ) -> ProviderHandle<Product> {
        let source = ProviderSource(container: self, factory: factory)
        add(Registration(key: Key(type, name: name), kind: .providerMarker))
        add(Registration(key: Key(AsyncProvider<Product>.self, name: name), kind: .sync { _ in
            source.provider()
        }))
        return ProviderHandle(source: source)
    }
}

/// Backs every `AsyncProvider` for one registration.
///
/// Checked `Sendable`: the factory is `@Sendable` and the shared-instance state is behind a `Mutex`.
final class ProviderSource<Product>: Sendable {
    let container: UnifiedContainer
    let factory: @Sendable (any Resolver) async throws -> sending Product
    private let shared = Mutex<AsyncProvider<Product>.Make?>(nil)

    init(container: UnifiedContainer, factory: @escaping @Sendable (any Resolver) async throws -> sending Product) {
        self.container = container
        self.factory = factory
    }

    func provider() -> AsyncProvider<Product> {
        if let shared = shared.withLock({ $0 }) {
            return AsyncProvider(make: shared)
        }
        return AsyncProvider(make: { [self] in
            try await self.factory(self.container)
        })
    }

    func setShared(_ make: @escaping AsyncProvider<Product>.Make) {
        shared.withLock { $0 = make }
    }
}

extension ProviderSource where Product: Sendable {
    func makeShared() {
        let cache = TaskCache<Product>()
        setShared { [self] in
            try await cache.value {
                try await self.factory(self.container)
            }
        }
    }
}

/// One in-flight or finished creation, shared by every caller.
final class TaskCache<Product: Sendable>: Sendable {
    private let task = Mutex<Task<Product, any Error>?>(nil)

    func value(_ create: @escaping @Sendable () async throws -> Product) async throws -> Product {
        let current = task.withLock { task -> Task<Product, any Error> in
            if let task {
                return task
            }
            let new = Task { try await create() }
            task = new
            return new
        }
        do {
            return try await current.value
        } catch {
            // Don't keep a failed creation; the next call tries again.
            task.withLock { if $0 == current { $0 = nil } }
            throw error
        }
    }
}
