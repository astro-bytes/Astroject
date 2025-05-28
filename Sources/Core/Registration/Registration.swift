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
    // TODO: Comment
    let queue = DispatchQueue(label: "com.astrobytes.astroject.registration.\(Product.self)")
    
    /// An array of actions to be performed after a product is resolved.
    private(set) var actions: [Action] = []
    
    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>
    
    public let isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - parameter factory: The factory used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product.
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
    /// This method first checks if an instance already exists for the current context.
    /// If not, it uses the registered factory to create a new instance, stores it according
    /// to the instance management strategy, and then runs any defined `afterInit` actions.
    ///
    /// - parameter container: The `Container` (acting as a `Resolver`) to use
    ///                        for resolving dependencies within the factory.
    /// - parameter context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(
        _ container: Container,
        with context: Context = .current
    ) async throws -> Product {
        if let product = instance.get(for: context) {
            return product
        } else {
            do {
                let product: Product = try await factory(container)
                instance.set(product, for: context)
                try runActions(container, product: product)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
    }
    
    /// Resolves and returns an instance of the product synchronously.
    ///
    /// This method first checks if an instance already exists for the current context.
    /// If not, it uses the registered factory to create a new instance, stores it according
    /// to the instance management strategy, and then runs any defined `afterInit` actions.
    ///
    /// - parameter container: The `Container` (acting as a `Resolver`) to use for resolving
    ///                        dependencies within the factory.
    /// - parameter context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(
        _ container: Container,
        with context: Context = .current
    ) throws -> Product {
        if let product = instance.get(for: context) {
            return product
        } else {
            do {
                let product: Product = try factory(container)
                instance.set(product, for: context)
                try runActions(container, product: product)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
    }
    
    /// Executes all registered `afterInit` actions for a given product.
    ///
    /// This method iterates through the `actions` array and executes each `Action` closure,
    /// passing the container and the newly resolved product.
    ///
    /// - Parameters:
    ///   - container: The `Container` to pass to the actions.
    ///   - product: The product instance on which to perform the actions.
    /// - Throws: `AstrojectError.afterInit` if any of the actions throw an error.
    public func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.afterInit(error)
        }
    }
    
    /// Changes the instance management strategy for this registration.
    ///
    /// This allows modifying how instances are cached and reused, for example switching
    /// between `Weak`, `Graph`, or other `Instance` implementations.
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
    /// These actions can be used for additional setup, such as dependency injection or lifecycle hooks.
    ///
    /// - Parameter action: A closure that accepts the resolver and the newly created product.
    /// - Returns: The updated `Registration` instance.
    @discardableResult
    public func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
    
    /// Compares this registration with another for equality within a specific resolution context.
    ///
    /// Unlike the standard `==` operator, which avoids resolution state, this method compares the actual
    /// resolved instances (if available) in a given `Context`. This is useful for testing or debugging scenarios
    /// where it's important to know whether two registrations yield the same instance under the same context.
    ///
    /// - Parameters:
    ///   - other: The other `Registration` instance to compare against.
    ///   - context: The resolution context in which to compare resolved instances. Defaults to `.current`.
    /// - Returns: `true` if both registrations have the same instance (in the given context),
    ///            use the same instance management strategy, have the same `isOverridable` flag,
    ///            and were created with the same factory; otherwise, `false`.
    public func isEqual(to other: Registration<Product>, in context: Context = .current) -> Bool where Product: Equatable {
        instance.get(for: context) == other.instance.get(for: context) &&
        self == other
    }
}

extension Registration: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    public static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        type(of: lhs.instance) == type(of: rhs.instance) &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory
    }
}
