//
// Transient.swift
// Astroject
//
// Created by Porter McGary on 2/26/25.
//

import Foundation

/// A transient instance that creates a new instance each time it's resolved.
///
/// The `Transient` class implements the `Instance` protocol and represents a transient scope for dependency injection.
/// Each time a dependency with a transient scope is resolved, a new instance of the product is created.
class Transient<Product>: Instance {
    /// Initializes a new `Transient` instance.
    init() {}
    
    func get(for: Context) -> Product? { nil }
    
    func set(_ product: Product, for: Context) {}
    
    func release(for: Context?) {}
}
