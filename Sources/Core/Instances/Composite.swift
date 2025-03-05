//
//  Composite.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A composite instance that manages a collection of instances.
public class Composite<Product>: Instance {
    /// An array of instances that this composite manages.
    var instances: [any Instance<Product>] = []
    
    /// Initializes a new Composite instance with the given array of instances.
    ///
    /// - Parameter instances: The array of instances to manage.
    public init(instances: [any Instance<Product>]) {
        self.instances = instances
    }
    
    /// Retrieves the first non-nil instance from the managed instances.
    ///
    /// - Returns: The first non-nil instance, or nil if none is found.
    public func get() -> Product? {
        instances.compactMap { $0.get() }.first
    }
    
    /// Sets the given product on all managed instances.
    ///
    /// - Parameter product: The product to set.
    public func set(_ product: Product) {
        instances.forEach { $0.set(product) }
    }
    
    /// Releases all managed instances.
    public func release() {
        instances.forEach { $0.release() }
    }
}
