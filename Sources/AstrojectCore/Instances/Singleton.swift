//
// Singleton.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A singleton instance that creates and stores a single instance of the product.
///
/// The `Singleton` class implements the `Instance` protocol and represents a singleton scope for dependency injection.
/// It ensures that only one instance of the product is created and stored throughout the application's lifecycle.
public class Singleton<Product>: Instance {
    /// The stored product instance.
    private var product: Product?
    
    /// Initializes a new `Singleton` instance.
    public init() {}
    
    /// Retrieves the stored product instance.
    ///
    /// This function returns the singleton instance of the product, if it has been set.
    /// If the instance has not been set yet, it returns `nil`.
    ///
    /// - Returns: The stored product instance, or `nil` if not yet set.
    public func get() -> Product? {
        return self.product
    }
    
    /// Sets the product instance if it hasn't been set yet.
    ///
    /// This function sets the singleton instance of the product.
    /// If the instance has already been set, it does nothing.
    ///
    /// - Parameter product: The product instance to set.
    public func set(_ product: Product) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    /// Does nothing, as the singleton instance is managed by the container.
    ///
    /// This function is a no-op because the singleton instance is managed by the container's lifecycle.
    /// Releasing the instance is not necessary.
    public func release() {}
}
