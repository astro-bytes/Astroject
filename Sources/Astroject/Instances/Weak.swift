//
//  Weak.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A weak instance that holds a weak reference to the product.
public class Weak<Product: AnyObject>: Instance {
    /// The weak reference to the product instance.
    weak var product: Product?
    
    /// Initializes a new Weak instance.
    public init() {}
    
    /// Retrieves the product instance from the weak reference.
    ///
    /// - Returns: The product instance, or nil if it has been deallocated.
    public func get() -> Product? {
        self.product
    }
    
    /// Sets the product instance in the weak reference.
    ///
    /// - Parameter product: The product instance to set.
    public func set(_ product: Product) {
        self.product = product
    }
    
    /// Releases the product instance by setting the weak reference to nil.
    public func release() {
        self.product = nil
    }
}
