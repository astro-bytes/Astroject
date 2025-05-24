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
    /// A closure type for actions to be performed after a product is resolved.
    public typealias Action = (Resolver, Product) throws -> Void

    /// The factory used to create instances of the product.
    let factory: Factory<Product, Resolver>

    /// An array of actions to be performed after a product is resolved.
    private var actions: [Action] = []

    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>

    /// Indicates whether this registration can be overridden by another registration.
    public let isOverridable: Bool

    /// Initializes a new `Registration` instance.
    ///
    /// - parameter factory: The factory used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product.
    public init(
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
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(_ container: Container) async throws -> Product {
        let context = Context.current

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
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(_ container: Container) throws -> Product {
        let context = Context.current

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
    /// - Throws: `AstrojectError.underlyingError` if any of the actions throw an error.
    public func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.underlyingError(error)
        }
    }

    @discardableResult
    public func `as`(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }

    @discardableResult
    public func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension Registration: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    public static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        let context = Context.current
        return lhs.instance.get(for: context) == rhs.instance.get(for: context) &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory
    }
}
