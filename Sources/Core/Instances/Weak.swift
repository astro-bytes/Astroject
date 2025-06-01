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
    private weak var object: AnyObject?
    
    /// The currently held product, if any.
    /// This weak reference will become `nil` once the product is deallocated.
    private(set) var product: Product? {
        get { object as? Product }
        set { object = newValue as AnyObject }
    }
    
    /// Initializes a new `Weak` instance.
    public required init() {}
    
    public func get(for: any Context) -> Product? {
        self.product
    }
    
    public func set(_ product: Product, for: any Context) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    public func release(for: (any Context)?) {
        self.product = nil
    }
}
