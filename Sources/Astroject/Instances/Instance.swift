//
//  Instance.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A protocol that defines the behavior of an instance managed by a dependency injection container.
public protocol Instance<Product> {
    /// The type of product that this instance manages.
    associatedtype Product
    
    /// Retrieves the managed product, if available.
    ///
    /// - Returns: The managed product, or nil if not available.
    func get() -> Product?
    
    /// Sets the managed product.
    ///
    /// - Parameter product: The product to set.
    func set(_ product: Product)
    
    /// Releases the managed product or performs any necessary cleanup.
    func release()
}
