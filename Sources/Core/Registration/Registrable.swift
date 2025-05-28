//
// Registrable.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a registrable component that can be resolved by a `Container`.
///
/// The `Registrable` protocol is used to define components that can be
/// registered with a dependency injection `Container`.
/// It provides methods for configuring the instance management scope and post
/// -initialization actions for the registered component.
public protocol Registrable<Product> {
    /// A closure type for actions to be performed after a product is resolved.
    associatedtype Action
    
    /// The type of product that this registrable component produces.
    associatedtype Product
    
    /// A boolean value indicating whether this registration can be overridden by another registration for
    /// the same product type.
    var isOverridable: Bool { get }
    
    /// Specifies the instance management strategy for the registered product.
    ///
    /// This function allows you to define how instances of the `Product` will be
    /// created and managed by the dependency injection container.
    ///
    /// - Parameter instance: The type of `Instance` (e.g., `Singleton.self`, `Transient.self`)
    ///   that will manage the product's lifecycle.
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func `as`(_ instance: any Instance<Product>.Type) -> Self
    
    /// Sets an action to be performed after the product is initialized.
    ///
    /// This function allows configuring a post-initialization action that will be
    /// executed after the product instance is created.
    ///
    /// - parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func afterInit(perform action: Action) -> Self
}

// MARK: Instance's
public extension Registrable {
    /// Specifies that the registered product should be a **singleton**.
    ///
    /// A singleton instance means that only one instance of the product will be
    /// created and reused throughout the application's lifecycle.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asSingleton() -> Self {
        return self.as(Singleton.self)
    }
    
    /// Specifies that the registered product should be a **weak** instance.
    ///
    /// A weak instance means that the container will hold a weak reference to the
    /// product. If no other strong references exist, the instance can be deallocated.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asWeak() -> Self {
        return self.as(Weak.self)
    }
    
    /// Specifies that a **new instance** of the product should be created **each time** it is resolved.
    ///
    /// This is often referred to as a "transient" or "factory" scope.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asTransient() -> Self {
        return self.as(Transient.self)
    }
    
    /// Specifies that the registered product should be scoped to its **dependency graph**.
    ///
    /// This means that a new instance will be created for each distinct resolution
    /// operation that involves this product, but if the product is a dependency
    /// within a larger graph, the same instance will be reused within that graph.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asGraph() -> Self {
        return self.as(Graph.self)
    }
}
