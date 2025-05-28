//
//  Resolver.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a resolver that can resolve dependencies.
///
/// The `Resolver` protocol is used to define the interface for resolving dependencies
/// within a dependency injection container.
/// Implementations of this protocol are responsible for providing instances of registered types.
public protocol Resolver {
    /// Resolves a product type asynchronously with an optional name.
    ///
    /// This function resolves a dependency of the specified `productType` with an optional `name`.
    /// The `name` parameter allows resolving named registrations, which can be useful
    /// when multiple registrations exist for the same type.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved, for example, if no registration is found.
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product
    
    /// Resolves a product type synchronously with an optional name.
    ///
    /// This function resolves a dependency of the specified `productType` with an optional `name`.
    /// This is for synchronous resolution only; if the registered factory is asynchronous,
    /// it will throw an error.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved, if no registration is found,
    ///           or if the factory is asynchronous.
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) throws -> Product
    
    /// Resolves a product type asynchronously with an optional name and an argument.
    ///
    /// This function resolves a dependency of the specified `productType` with an optional `name` and an `argument`.
    /// The `name` parameter allows resolving named registrations, which is useful when multiple registrations exist
    /// for the same type. The `argument` parameter is used to pass a value required by the factory to create
    /// the instance.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - parameter argument: An argument required to resolve the dependency.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved, for example, if no registration is found
    ///           or if the argument type does not match.
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product
    
    /// Resolves a product type synchronously with an optional name and an argument.
    ///
    /// This function resolves a dependency of the specified `productType` with an optional `name` and an `argument`.
    /// This is for synchronous resolution only; if the registered factory is asynchronous, it will throw an error.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - parameter argument: An argument required to resolve the dependency.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved, if no registration is found,
    ///           if the argument type does not match, or if the factory is asynchronous.
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product
}

/// ### Default Implementations for `Resolver`
/// These extensions provide convenience methods for resolving dependencies,
/// allowing for more concise code when the `name` parameter can use its default `nil` value.
public extension Resolver {
    /// Default implementation for resolving a product type without a name.
    ///
    /// This default implementation calls the `resolve(productType:name:)` function with a `nil` name,
    /// effectively resolving the default asynchronous registration for the given `productType`.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration. Defaults to `nil`.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product>(_ productType: Product.Type, name: String? = nil) async throws -> Product {
        try await resolve(productType: productType, name: name)
    }
    
    /// Default implementation for resolving a product type synchronously without a name.
    ///
    /// This default implementation calls the `resolve(productType:name:)` function with a `nil` name,
    /// effectively resolving the default synchronous registration for the given `productType`.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration. Defaults to `nil`.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved synchronously.
    func resolve<Product>(
        _ productType: Product.Type,
        name: String? = nil
    ) throws -> Product {
        try resolve(productType: productType, name: name)
    }
    
    /// Default implementation for resolving a product type asynchronously with an argument but without a name.
    ///
    /// This default implementation calls the `resolve(productType:name:argument:)` function with a `nil` name,
    /// effectively resolving the default asynchronous registration for the given `productType` and `argument`.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration. Defaults to `nil`.
    /// - parameter argument: The argument needed to resolve the dependency.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved.
    func resolve<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument
    ) async throws -> Product {
        try await resolve(productType: productType, name: name, argument: argument)
    }
    
    /// Default implementation for resolving a product type synchronously with an argument but without a name.
    ///
    /// This default implementation calls the `resolve(productType:name:argument:)` function with a `nil` name,
    /// effectively resolving the default synchronous registration for the given `productType` and `argument`.
    ///
    /// - parameter productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration. Defaults to `nil`.
    /// - parameter argument: The argument needed to resolve the dependency.
    /// - Returns: The resolved product instance.
    /// - Throws: An error if the product cannot be resolved synchronously.
    func resolve<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument
    ) throws -> Product {
        try resolve(productType: productType, name: name, argument: argument)
    }
}
