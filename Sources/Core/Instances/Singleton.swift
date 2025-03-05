//
//  Singleton.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A singleton instance that creates and stores a single instance of the product.
public class Singleton<Product>: Instance {
    /// The stored product instance.
    var product: Product?
    
    /// Initializes a new Singleton instance.
    public init() {}
    
    /// Retrieves the stored product instance.
    ///
    /// - Returns: The stored product instance, or nil if not yet set.
    public func get() -> Product? {
        self.product
    }
    
    /// Sets the product instance if it hasn't been set yet.
    ///
    /// - Parameter product: The product instance to set.
    public func set(_ product: Product) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    /// Does nothing, as the singleton instance is managed by the container.
    public func release() {}
}
