//
// Resolver.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a resolver that can resolve dependencies.
///
/// The `Resolver` protocol is used to define the interface for resolving dependencies
/// within a dependency injection container.
/// Implementations of this protocol are responsible for providing instances of registered types.
public protocol Resolver {
    /// Resolves a product type asynchronously.
    ///
    /// This function resolves a dependency of the specified `productType` without a specific name.
    /// It uses the default registration for the given type.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type) async throws -> Product
    
    /// Resolves a product type asynchronously with an optional name.
    ///
    /// This function resolves a dependency of the specified `productType` with an optional `name`.
    /// The `name` parameter allows resolving named registrations, which can be useful
    /// when multiple registrations exist for the same type.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(
        _ productType: Product.Type,
        name: String?
    ) async throws -> Product
    
    // TODO: Comment
    func resolve<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product
}

public extension Resolver {
    /// Default implementation for resolving a product type without a name.
    ///
    /// This default implementation calls the `resolve(_:name:)` function with a `nil` name,
    /// effectively resolving the default registration for the given `productType`.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type) async throws -> Product {
        try await resolve(productType, name: nil)
    }
    
    // TODO: Comment
    func resolve<Product, Argument: Hashable>(_ productType: Product.Type, argument: Argument) async throws -> Product {
        try await resolve(productType, name: nil, argument: argument)
    }
}
