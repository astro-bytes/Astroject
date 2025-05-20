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
    
    /// Sets the instance management scope for the registration.
    ///
    /// This function allows configuring how the registered component's instances are
    /// managed, such as singleton, transient, or weak references.
    ///
    /// - parameter instance: The instance management strategy.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self
    
    /// Sets the instance management scope for the registration with an argument.
    ///
    /// This function allows configuring how the registered component's instances are
    /// managed when the registration requires an argument, such as singleton, transient,
    /// or weak references.
    ///
    /// - parameter instance: The instance management strategy.
    /// - parameter argument: The argument used to resolve the instance.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`<Argument: Hashable>(_ instance: any Instance<Product>, with argument: Argument) throws -> Self
    
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

public extension Registrable {
    /// Provides a default implementation that throws an error for the `as` function with an argument.
    ///
    /// This default implementation is used when a specific `Registration` class does not
    /// provide its own implementation for handling instances with arguments.  It indicates
    /// that this type of registration does not support argument-specific instance management.
    ///
    /// - parameter instance: The instance management strategy.
    /// - parameter argument: The argument used to resolve the instance.
    /// - Returns: The modified `Registration` instance.
    /// - Throws: `AstrojectError.invalidInstance` indicating that this registration does not support arguments.
    @discardableResult
    func `as`<Argument: Hashable>(_ instance: any Instance<Product>, with argument: Argument) throws -> Self {
        throw AstrojectError.invalidInstance
    }
}

// MARK: Instance's
public extension Registrable {
    /// Sets the instance management scope to `Singleton`.
    ///
    /// This function sets the instance management scope to `Singleton`,
    /// ensuring that only one instance of the product is created and shared.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asSingleton() -> Self {
        return self.as(Singleton())
    }
    
    /// Sets the instance management scope to `Weak`.
    ///
    /// This function sets the instance management scope to `Weak`, holding a weak reference to the product instance.
    /// The instance will be deallocated when no longer strongly referenced elsewhere.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asWeak() -> Self where Product: AnyObject {
        return self.as(Weak())
    }
    
    /// Sets the instance management scope to `Transient`.
    ///
    /// This function sets the instance management scope to `Transient`,
    /// creating a new instance of the product each time it is resolved.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asTransient() -> Self {
        return self.as(Transient())
    }
    
    /// Sets the instance management scope to `Graph`.
    ///
    /// This function sets the instance management scope to `Graph`,
    /// allowing the instance to be managed within a specific graph or hierarchy,
    /// enabling scoped instance management.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asGraph() -> Self {
        return self.as(Graph())
    }
}
