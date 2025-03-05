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
    
    /// Retrieves the managed product, if available.
    ///
    /// This function returns the instance of the product being managed by the `Instance` implementation.
    /// If the instance has not been set or has been released, it returns `nil`.
    ///
    /// - Returns: The managed product, or `nil` if not available.
    func get() -> Product?
    
    /// Sets the managed product.
    ///
    /// This function sets the instance of the product being managed by the `Instance` implementation.
    ///
    /// - Parameter product: The product to set.
    func set(_ product: Product)
    
    /// Releases the managed product or performs any necessary cleanup.
    ///
    /// This function releases the managed product, performing any necessary cleanup or deallocation.
    /// After calling this function, `get()` should return `nil`.
    func release()
}
