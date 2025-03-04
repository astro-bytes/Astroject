//
//  Registration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a registration of a product with a factory and instance management strategy.
actor Registration<Product: Sendable>: Registrable {
    typealias Action = @Sendable (Resolver, Product) throws -> Void
    typealias Factory = @Sendable (Resolver) async throws -> Product
    
    /// The factory used to create instances of the product.
    let factory: Factory
    
    /// The container
    weak var container: Container?
    
    /// An array of actions to be performed after a product is resolved.
    var actions: [Action] = []
    
    /// The instance management strategy for the product.
    var instance: any Instance<Product>
    
    /// Indicates whether this registration can be overridden by another registration.
    let isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - Parameters:
    ///   - factory: The factory used to create instances of the product.
    ///   - isOverridable: Indicates whether this registration can be overridden.
    ///   - instance: The instance management strategy for the product (default is `Prototype`).
    init(
        _ container: Container,
        factory: @escaping Factory,
        isOverridable: Bool,
        instance: any Instance<Product> = Prototype<Product>()
    ) {
        self.container = container
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    /// Resolves the product instance synchronously.
    ///
    /// - Parameter container: The container used for dependency resolution.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.asyncResolutionRequired` if an async factory is used, or `ResolutionError.underlyingError` if an error occurs during creation.
    func resolve() async throws -> Product {
        if let product = await self.instance.get() {
            return product
        } else {
            guard let container else { throw ResolutionError.containerDeallocated }
            let product = try await factory(container)
            await self.instance.set(product)
            try runActions(product: product)
            return product
        }
    }
    
    /// Runs the post-initialization actions.
    ///
    /// - Parameters:
    ///   - container: The container used for dependency resolution.
    ///   - product: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during action execution.
    func runActions(product: Product) throws {
        do {
            guard let container else { throw RegistrationError.containerDeallocated }
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

extension Registration where Product: Equatable {
    func isEqual(to other: Registration<Product>) async -> Bool {
        guard let container, let otherContainer = await other.container else {
            return false
        }
        
        let instance = await self.instance.get() == (await other.instance.get())
        let isOverridable = self.isOverridable == other.isOverridable
        let factory = try? await self.factory(container) == (await other.factory(otherContainer))
        return instance && isOverridable && (factory ?? false)
    }
}
