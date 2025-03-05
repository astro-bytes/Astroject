//
// Prototype.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A prototype instance that creates a new instance each time it's resolved.
///
/// The `Prototype` class implements the `Instance` protocol and represents a prototype scope for dependency injection.
/// Each time a dependency with a prototype scope is resolved, a new instance of the product is created.
public class Prototype<Product>: Instance {
    /// Initializes a new `Prototype` instance.
    public init() {}
    
    /// Always returns `nil`, as a new instance should be created each time.
    ///
    /// This function adheres to the prototype scope by not storing or returning any previously created instance.
    ///
    /// - Returns: `nil`.
    public func get() -> Product? {
        return nil
    }
    
    /// Does nothing, as a new instance is created each time.
    ///
    /// This function is a no-op because the prototype scope does not manage a single instance.
    /// Any provided product is ignored.
    ///
    /// - Parameter product: The product to set (ignored).
    public func set(_ product: Product) {}
    
    /// Does nothing, as there's no instance to release.
    ///
    /// This function is a no-op because the prototype scope does not manage a
    /// single instance that needs to be released.
    public func release() {}
}
