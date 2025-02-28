//
//  Prototype.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A prototype instance that creates a new instance each time it's resolved.
public class Prototype<Product>: Instance {
    /// Initializes a new Prototype instance.
    public init() {}
    
    /// Always returns nil, as a new instance should be created each time.
    ///
    /// - Returns: nil.
    public func get() -> Product? { nil }
    
    /// Does nothing, as a new instance is created each time.
    ///
    /// - Parameter product: The product to set (ignored).
    public func set(_ product: Product) {}
    
    /// Does nothing, as there's no instance to release.
    public func release() {}
}
