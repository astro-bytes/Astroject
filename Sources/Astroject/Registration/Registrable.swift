//
//  Registrable.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a registrable component that can be resolved by a `Container`.
public protocol Registrable<Product>: Sendable {
    /// A closure type for actions to be performed after a product is resolved.
    associatedtype Action: Sendable
    
    /// The type of product that this registrable component produces.
    associatedtype Product: Sendable
    
    /// Sets the instance management scope for the registration.
    ///
    /// - Parameter instance: The instance management strategy.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`(_ instance: any Instance<Product>) async -> Self
    
    @discardableResult
    func afterInit(perform action: Action) async -> Self
}

public extension Registrable {
    /// Sets the instance management scope to `Singleton`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asSingleton() async -> Self {
        await self.as(Singleton())
    }
    
    /// Sets the instance management scope to `Weak`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asWeak() async -> Self where Product: AnyObject {
        await self.as(Weak())
    }
    
    /// Sets the instance management scope to `Prototype`.
    ///
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func asPrototype() async -> Self {
        await self.as(Prototype())
    }
}
