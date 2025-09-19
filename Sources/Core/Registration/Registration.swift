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
    public typealias Argument = Empty
    public typealias Action = (Resolver, Product) throws -> Void
    
    /// The factory used to create instances of the product.
    let factory: Factory<Product, Resolver>
    
    /// The container in which this registration is stored.
    ///
    /// It is used primarily to enable operations such as type forwarding (`implements`)
    /// so that the registration can participate in broader container-level resolution behaviors.
    /// Although not directly involved in instance creation, it is essential for supporting
    /// registration metadata and container coordination.
    let container: any Container
    
    /// An array of actions to be performed after a product is resolved.
    private(set) var actions: [Action] = []
    
    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>
    
    public let isOverridable: Bool
    public let argumentType: Any.Type = Empty.self
    public let key: RegistrationKey
    
    /// Initializes a new `Registration` instance.
    ///
    /// - Parameters:
    ///   - factory: The factory used to create instances of the product.
    ///   - isOverridable: Indicates whether this registration can be overridden.
    ///   - instanceType: The type of instance strategy used for managing product lifecycles.
    public init(
        container: any Container,
        key: RegistrationKey,
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instanceType: any Instance<Product>.Type
    ) {
        self.container = container
        self.key = key
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
        container: any Container,
        key: RegistrationKey,
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instance: any Instance<Product>
    ) {
        self.container = container
        self.key = key
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    public func resolve<Argument>(
        container: Container,
        argument: Argument,
        in context: any Context
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
    
    public func resolve<Argument>(
        container: Container,
        argument: Argument,
        in context: any Context
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
    
    @discardableResult
    public func `as`(_ instance: any Instance<Product>.Type) -> Self {
        self.instance = instance.init()
        return self
    }
    
    @discardableResult
    public func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
    
    @discardableResult
    public func implements<T>(_ type: T.Type) -> Self {
        container.forward(type, to: self)
        return self
    }
    
    public func release<A>(with argument: A, in context: any Context) throws {
        instance.release(for: context)
    }
}

extension Registration: Equatable where Product: Equatable {
    public func isEqual(
        to other: Registration<Product>,
        in context: any Context = ResolutionContext.currentContext
    ) -> Bool {
        instance.get(for: context) == other.instance.get(for: context) &&
        self == other
    }
    
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
