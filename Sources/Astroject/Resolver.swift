//
//  Resolver.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a resolver that can resolve dependencies.
public protocol Resolver {
    /// Resolves a product type synchronously.
    ///
    /// - Parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type) throws -> Product
    
    /// Resolves a product type synchronously with an optional name.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type, name: String?) throws -> Product
    
    /// Resolves a product type asynchronously.
    ///
    /// - Parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolveAsync<Product>(_ productType: Product.Type) async throws -> Product
    
    /// Resolves a product type asynchronously with an optional name.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolveAsync<Product>(_ productType: Product.Type, name: String?) async throws -> Product
}

public extension Resolver {
    /// Default implementation for resolving a product type without a name.
    ///
    /// - Parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type) throws -> Product {
        try resolve(productType, name: nil)
    }
    
    /// Default implementation for resolving a product type asynchronously without a name.
    ///
    /// - Parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolveAsync<Product>(_ productType: Product.Type) async throws -> Product {
        try await resolveAsync(productType, name: nil)
    }
}
