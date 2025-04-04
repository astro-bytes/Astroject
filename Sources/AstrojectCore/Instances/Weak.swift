//
// Weak.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A weak instance that holds a weak reference to the product.
///
/// The `Weak` class implements the `Instance` protocol and represents a weak reference scope for dependency injection.
/// It holds a weak reference to the product instance, allowing it to be deallocated when
/// no longer strongly referenced elsewhere.
public class Weak<Product: AnyObject>: Instance {
    /// The weak reference to the product instance.
    weak var product: Product?
    
    /// Initializes a new `Weak` instance.
    public init() {}
    
    public func get() -> Product? {
        self.product
    }
    
    public func set(_ product: Product) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    public func release() {
        self.product = nil
    }
}
