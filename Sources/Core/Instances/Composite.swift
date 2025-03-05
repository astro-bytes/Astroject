//
// Composite.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A composite instance that manages a collection of instances.
///
/// The `Composite` class implements the `Instance` protocol and provides a way to manage a collection of instances.
/// It allows you to treat multiple instances as a single entity, delegating operations to each managed instance.
public class Composite<Product>: Instance {
    /// An array of instances that this composite manages.
    private var instances: [any Instance<Product>] = []
    
    /// Initializes a new `Composite` instance with the given array of instances.
    ///
    /// - Parameter instances: The array of instances to manage.
    public init(instances: [any Instance<Product>]) {
        self.instances = instances
    }
    
    /// Retrieves the first non-nil instance from the managed instances.
    ///
    /// This function iterates through the managed instances and returns the first non-nil product instance it finds.
    /// If all managed instances return `nil`, this function also returns `nil`.
    ///
    /// - Returns: The first non-nil instance, or `nil` if none is found.
    public func get() -> Product? {
        return instances.compactMap { $0.get() }.first
    }
    
    /// Sets the given product on all managed instances.
    ///
    /// This function iterates through the managed instances and sets the given product on each one.
    ///
    /// - Parameter product: The product to set.
    public func set(_ product: Product) {
        instances.forEach { $0.set(product) }
    }
    
    /// Releases all managed instances.
    ///
    /// This function iterates through the managed instances and releases each one.
    public func release() {
        instances.forEach { $0.release() }
    }
}
