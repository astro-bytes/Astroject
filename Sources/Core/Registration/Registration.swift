//
// Registration.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a registration of a product with a factory and instance management strategy.
///
/// The `Registration` class implements the `Registrable` protocol and manages the lifecycle of a registered product.
/// It holds the factory used to create instances, the instance management strategy,
/// and any post-initialization actions.
public final class Registration<Product>: Registrable {
    
    public typealias Action = (Resolver, Product) throws -> Void
    
    /// The factory used to create instances of the product.
    let factory: Factory<Product, Resolver>
    
    /// An array of actions to be performed after a product is resolved.
    private(set) var actions: [Action] = []
    
    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>
    
    /// Indicates whether this registration can be overridden by another.
    public let isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - Parameters:
    ///   - factory: The factory used to create instances of the product.
    ///   - isOverridable: Indicates whether this registration can be overridden.
    ///   - instanceType: The type of instance strategy used for managing product lifecycles.
    public init(
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instanceType: any Instance<Product>.Type
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instanceType.init()
    }
    
    /// Initializes a new `Registration` with a pre-existing instance strategy.
    ///
    /// This initializer is primarily intended for testing, allowing you to inject a custom
    /// `Instance` implementation to inspect or control resolution behavior.
    ///
    /// - Parameters:
    ///   - factory: The factory used to create instances of the product.
    ///   - isOverridable: Indicates whether this registration can be overridden.
    ///   - instance: A custom instance management strategy to use, often a mock.
    init(
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instance: any Instance<Product>
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    /// Resolves and returns an instance of the product asynchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(
        _ container: Container,
        with context: any Context = ResolutionContext.currentContext
    ) async throws -> Product {
        guard let product = instance.get(for: context) else {
            do {
                let product: Product = try await factory(container)
                instance.set(product, for: context)
                try runActions(for: product, in: container)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        
        return product
    }
    
    /// Resolves and returns an instance of the product synchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(
        _ container: Container,
        with context: any Context = ResolutionContext.currentContext
    ) throws -> Product {
        guard let product = instance.get(for: context) else {
            do {
                let product: Product = try factory(container)
                instance.set(product, for: context)
                try runActions(for: product, in: container)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        
        return product
    }
    
    /// Changes the instance management strategy for this registration.
    ///
    /// - Parameter instance: The type of `Instance` to use.
    /// - Returns: The updated `Registration` instance.
    @discardableResult
    public func `as`(_ instance: any Instance<Product>.Type) -> Self {
        self.instance = instance.init()
        return self
    }
    
    /// Adds a post-initialization action to be run after a product is created.
    ///
    /// - Parameter action: A closure that accepts the resolver and the newly created product.
    /// - Returns: The updated `Registration` instance.
    @discardableResult
    public func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension Registration: Equatable where Product: Equatable {
    /// Compares this registration with another for equality within a specific resolution context.
    ///
    /// - Parameters:
    ///   - other: The other `Registration` instance to compare against.
    ///   - context: The resolution context in which to compare resolved instances. Defaults to `.current`.
    /// - Returns: `true` if both registrations have the same instance (in the given context),
    ///            use the same instance management strategy, have the same `isOverridable` flag,
    ///            and were created with the same factory; otherwise, `false`.
    public func isEqual(
        to other: Registration<Product>,
        in context: any Context = ResolutionContext.currentContext
    ) -> Bool {
        instance.get(for: context) == other.instance.get(for: context) &&
        self == other
    }
    
    /// Checks if two registrations are equal.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side registration.
    ///   - rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    public static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        type(of: lhs.instance) == type(of: rhs.instance) &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory
    }
}

extension Registration {
    /// Executes all registered `afterInit` actions for a given product.
    ///
    /// - Parameters:
    ///   - container: The `Container` to pass to the actions.
    ///   - product: The product instance on which to perform the actions.
    /// - Throws: `AstrojectError.afterInit` if any of the actions throw an error.
    func runActions(for product: Product, in container: Container) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.afterInit(error)
        }
    }
}
