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
    
    /// Retrieves the product instance from the weak reference.
    ///
    /// This function returns the product instance, if it is still allocated.
    /// If the instance has been deallocated, it returns `nil`.
    ///
    /// - Returns: The product instance, or `nil` if it has been deallocated.
    public func get() -> Product? {
        return self.product
    }
    
    /// Sets the product instance in the weak reference.
    ///
    /// This function sets the product instance as a weak reference.
    /// The instance will be deallocated when no longer strongly referenced elsewhere.
    ///
    /// - Parameter product: The product instance to set.
    public func set(_ product: Product) {
        self.product = product
    }
    
    /// Releases the product instance by setting the weak reference to `nil`.
    ///
    /// This function explicitly sets the weak reference to `nil`, effectively releasing the product instance.
    /// However, the instance may still be deallocated by the system if no other strong references exist.
    public func release() {
        self.product = nil
    }
}
