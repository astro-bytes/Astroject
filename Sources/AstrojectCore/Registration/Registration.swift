//
// Registration.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

// TODO: Add Sync Version

/// Represents a registration of a product with a factory and instance management strategy.
///
/// The `Registration` class implements the `Registrable` protocol and manages the lifecycle of a registered product.
/// It holds the factory used to create instances, the instance management strategy,
/// and any post-initialization actions.
class Registration<Product>: Registrable {
    /// A closure type for actions to be performed after a product is resolved.
    typealias Action = (Resolver, Product) throws -> Void
    
    /// The factory used to create instances of the product.
    let factory: Factory<Product, Resolver>
    
    /// An array of actions to be performed after a product is resolved.
    private var actions: [Action] = []
    
    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>
    
    /// Indicates whether this registration can be overridden by another registration.
    let isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - parameter factory: The factory used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product.
    init(
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instance: any Instance<Product>
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    /// Initializes a new `Registration` instance with a factory closure.
    ///
    /// - parameter block: The factory closure used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product.
    convenience init(
        factory block: @escaping Factory<Product, Resolver>.Block,
        isOverridable: Bool,
        instance: any Instance<Product>
    ) {
        self.init(
            factory: Factory(block),
            isOverridable: isOverridable,
            instance: instance
        )
    }
    
    func resolve(_ container: Container) async throws -> Product {
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
    
    private func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.underlyingError(error)
        }
    }
    
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    @discardableResult
    func afterInit(perform action: @escaping Action) -> Self {
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
    static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        let context = Context.current
        return lhs.instance.get(for: context) == rhs.instance.get(for: context) &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory
    }
}
