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
    
    public func get() -> Product? { nil }
    
    public func set(_ product: Product) {}
    
    public func release() {}
}
