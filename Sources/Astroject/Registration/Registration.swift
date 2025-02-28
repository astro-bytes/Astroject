//
//  Registration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a registration of a product with a factory and instance management strategy.
public class Registration<Product>: Registrable {
    /// A closure type for actions to be performed after a product is resolved.
    public typealias Action = (Resolver, Product) throws -> Void
    
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
    
    /// Resolves the product instance synchronously.
    ///
    /// - Parameter container: The container used for dependency resolution.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.asyncResolutionRequired` if an async factory is used, or `ResolutionError.underlyingError` if an error occurs during creation.
    func resolve(_ container: Container) throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            let product: Product
            switch factory {
            case .async:
                throw ResolutionError.asyncResolutionRequired
            case .sync(let closure):
                product = try closure(container)
            }
            self.instance.set(product)
            try runActions(container, product: product)
            return product
        }
    }
    
    /// Resolves the product instance asynchronously.
    ///
    /// - Parameter container: The container used for dependency resolution.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during creation.
    func resolveAsync(_ container: Container) async throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            let product: Product
            switch factory {
            case .async(let closure):
                product = try await closure(container)
            case .sync(let closure):
                product = try closure(container)
            }
            self.instance.set(product)
            try runActions(container, product: product)
            return product
        }
    }
    
    /// Runs the post-initialization actions.
    ///
    /// - Parameters:
    ///   - container: The container used for dependency resolution.
    ///   - product: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during action execution.
    private func runActions(_ container: Container, product: Product) throws {
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
    public func scope(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    /// Sets the instance management scope to `Singleton`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    public func singletonScope() -> Self {
        self.scope(Singleton())
    }
    
    /// Sets the instance management scope to `Weak`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    public func weakScope() -> Self where Product: AnyObject {
        self.scope(Weak())
    }
    
    /// Sets the instance management scope to `Prototype`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    public func prototypeScope() -> Self {
        self.scope(Prototype())
    }
    
    /// Adds a post-initialization action to the registration.
    ///
    /// - Parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    public func postInitAction(_ action: @escaping Action) -> Self {
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
    public static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        lhs.instance.get() == rhs.instance.get() && lhs.isOverridable == rhs.isOverridable && lhs.factory == rhs.factory
    }
}
