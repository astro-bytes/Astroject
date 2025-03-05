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
    /// managed, such as singleton, prototype, or weak references.
    ///
    /// - Parameter instance: The instance management strategy.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self
    
    /// Sets an action to be performed after the product is initialized.
    ///
    /// This function allows configuring a post-initialization action that will be
    /// executed after the product instance is created.
    ///
    /// - Parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func afterInit(perform action: Action) -> Self
}

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
    
    /// Sets the instance management scope to `Prototype`.
    ///
    /// This function sets the instance management scope to `Prototype`,
    /// creating a new instance of the product each time it is resolved.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asPrototype() -> Self {
        return self.as(Prototype())
    }
}
