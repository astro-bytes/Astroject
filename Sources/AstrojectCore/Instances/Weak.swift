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
class Weak<Product>: Instance {
    /// The weak reference to the product instance.
    weak var object: AnyObject?
    
    var product: Product? {
        get { object as? Product }
        set { object = newValue as AnyObject }
    }
    
    /// Initializes a new `Weak` instance.
    init() {}
    
    func get(for: Context) -> Product? {
        self.product
    }
    
    func set(_ product: Product, for: Context) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    func release(for: Context?) {
        self.product = nil
    }
}
