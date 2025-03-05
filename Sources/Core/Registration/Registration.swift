//
//  Registration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a registration of a product with a factory and instance management strategy.
class Registration<Product>: Registrable {
    typealias Action = (Resolver, Product) throws -> Void
    
    /// The factory used to create instances of the product.
    let factory: Factory<Product>
    
    /// An array of actions to be performed after a product is resolved.
    var actions: [Action] = []
    
    /// The instance management strategy for the product.
    var instance: any Instance<Product>
    
    /// Indicates whether this registration can be overridden by another registration.
    var isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - Parameters:
    ///   - factory: The factory used to create instances of the product.
    ///   - isOverridable: Indicates whether this registration can be overridden.
    ///   - instance: The instance management strategy for the product (default is `Prototype`).
    init(factory: Factory<Product>,
         isOverridable: Bool,
         instance: any Instance<Product> = Prototype<Product>()
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    init(factory block: @escaping Factory<Product>.Block,
         isOverridable: Bool,
         instance: any Instance<Product> = Prototype<Product>()
    ) {
        let factory = Factory(block)
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    /// Resolves the product instance synchronously.
    ///
    /// - Parameter container: The container used for dependency resolution.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.asyncResolutionRequired` if an async factory is used, or `ResolutionError.underlyingError` if an error occurs during creation.
    func resolve(_ container: Container) async throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            do {
                let product: Product = try await factory(container)
                self.instance.set(product)
                try runActions(container, product: product)
                return product
            } catch {
                throw ResolutionError.underlyingError(error)
            }
        }
    }
    
    /// Runs the post-initialization actions.
    ///
    /// - Parameters:
    ///   - container: The container used for dependency resolution.
    ///   - product: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during action execution.
    func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw ResolutionError.underlyingError(error)
        }
    }
    
    /// Sets the instance management scope for the registration.
    ///
    /// - Parameter instance: The instance management strategy.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    /// Adds a post-initialization action to the registration.
    ///
    /// - Parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension Registration: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side registration.
    ///   - rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        lhs.instance.get() == rhs.instance.get() && lhs.isOverridable == rhs.isOverridable && lhs.factory == rhs.factory
    }
}
