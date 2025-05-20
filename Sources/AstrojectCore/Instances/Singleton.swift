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
class Singleton<Product>: Instance {
    /// The stored product instance.
    private var product: Product?
    
    /// Initializes a new `Singleton` instance.
    init() {}
    
    func get(for: Context) -> Product? {
        self.product
    }
    
    func set(_ product: Product, for: Context) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    func release(for: Context?) {}
}
