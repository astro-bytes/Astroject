//
// Instance.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A protocol that defines the behavior of an instance managed by a dependency injection container.
///
/// The `Instance` protocol provides a standardized interface for managing the
/// lifecycle of objects within a dependency injection container.
/// Implementations of this protocol are responsible for storing, retrieving, and releasing
/// instances of a specific product type.
public protocol Instance<Product> {
    /// The type of product that this instance manages.
    associatedtype Product
    
    /// Initializes a new instance manager.
    ///
    /// This initializer is typically used by the dependency injection container
    /// to create and configure an instance manager for a specific product type.
    init()
    
    /// Retrieves a product instance from the instance manager based on the provided context.
    /// - Parameter context: The `Context` object containing information pertinent to the instance's retrieval,
    ///   such as a `graphID` for scoped instances.
    /// - Returns: The `Product` instance if found, otherwise `nil`.
    func get(for context: any Context) -> Product?
    
    /// Stores or updates a product instance within the instance manager for a given context.
    /// - Parameters:
    ///   - product: The `Product` instance to be stored.
    ///   - context: The `Context` object used to associate the product with a specific scope or identifier.
    func set(_ product: Product, for context: any Context)
    
    /// Releases (removes) a product instance, or all instances, from the instance manager.
    /// - Parameter context: An optional `Context` object. If provided, only the product associated
    ///   with this context's `graphID` is released. If `nil`, all managed instances are released.
    func release(for context: (any Context)?)
}

public extension Instance {
    /// Releases all product instances currently managed by this instance manager.
    ///
    /// This is a convenience method that calls `release(for:)` with a `nil` context,
    /// effectively clearing all stored instances.
    func releaseAll() {
        self.release(for: nil)
    }
}
