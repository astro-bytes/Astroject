//
//  Container.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation

/// A protocol defining the core functionalities of a dependency injection container.
///
/// A `Container` is responsible for **registering** and **resolving** dependencies.
/// It acts as both a registration point for types and a resolver for their instances.
/// Conformance to `Sendable` ensures that `Container` implementations can be safely
/// used across concurrent environments.
public protocol Container: Resolver, Sendable {
    /// Registers a factory for a product that does not require an argument for resolution.
    ///
    /// Use this method to bind a `productType` to a `factory` closure. When the product
    /// is later resolved, the provided `factory` will be executed to create its instance.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate multiple registrations of the same `productType`.
    ///   - isOverridable: A boolean indicating whether this registration can be overridden by
    ///                    subsequent registrations with the same key. Defaults to `true`.
    ///   - factory: A `Factory` closure that takes a `Resolver` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance representing this registration, allowing for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration
    ///           for the same `productType` and `name` already exists.
    @discardableResult
    func register<Product>(
        productType: Product.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product>
    
    /// Registers a factory for a product that requires an argument for resolution.
    ///
    /// This method allows you to register factories that depend on an external argument
    /// provided at the time of resolution.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required by the product's factory.
    ///   - name: An optional name to differentiate multiple registrations of the same `productType`
    ///           with the same `argumentType`.
    ///   - isOverridable: A boolean indicating whether this registration can be overridden.
    ///                    Defaults to `true`.
    ///   - factory: A `Factory` closure that takes a `Resolver` and an `Argument`,
    ///              then returns an instance of `Product`.
    /// - Returns: The `Registrable` instance representing this registration, allowing for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration
    ///           for the same `productType`, `argumentType`, and `name` already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product>
    
    /// Checks if a registration exists for a given product type and optional name.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to check for registration.
    ///   - name: An optional name associated with the registration.
    /// - Returns: `true` if a registration exists for the specified `productType` and `name`, `false` otherwise.
    func isRegistered<Product>(productType: Product.Type, with name: String?) -> Bool
    
    /// Checks if a registration exists for a given product type, optional name, and argument type.
    ///
    /// This method is used for registrations that require an argument to differentiate them
    /// from other registrations of the same `productType`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to check for registration.
    ///   - name: An optional name associated with the registration.
    ///   - argumentType: The type of the argument associated with the registration.
    /// - Returns: `true` if a registration exists for the specified types and name, `false` otherwise.
    func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool
    
    /// Clears all existing registrations from the container.
    ///
    /// This method removes all registered factories and instances, effectively resetting
    /// the container to its initial empty state. Use with caution, especially in production
    /// environments, as it will invalidate all previously resolved dependencies.
    func clear()
    
    /// Adds a behavior to the container.
    ///
    /// Behaviors allow you to inject custom logic into the dependency registration
    /// and resolution lifecycle (e.g., for logging, analytics, etc.).
    ///
    /// - Parameter behavior: The `Behavior` instance to add.
    func add(_ behavior: Behavior)
}

/// ### Default Implementations for `Container`
///
/// These extensions provide convenience methods for registering and checking dependencies,
/// allowing for more concise code when `name` or `isOverridable` parameters can use their defaults.
public extension Container {
    /// Registers a factory for a product that does not require an argument,
    /// with `name` defaulting to `nil` and `isOverridable` defaulting to `true`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if the registration can be overridden. Defaults to `true`.
    ///   - factory: The factory closure.
    /// - Returns: The `Registrable` instance.
    /// - Throws: `AstrojectError.alreadyRegistered` if an unoverridable registration exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: factory
        )
    }
    
    /// Registers a factory for a product that requires an argument,
    /// with `name` defaulting to `nil` and `isOverridable` defaulting to `true`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required.
    ///   - name: An optional name. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if the registration can be overridden. Defaults to `true`.
    ///   - factory: The factory closure.
    /// - Returns: The `Registrable` instance.
    /// - Throws: `AstrojectError.alreadyRegistered` if an unoverridable registration exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: factory
        )
    }
    
    /// Checks if a registration exists for a given product type, with the name defaulting to `nil`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to check.
    ///   - name: An optional name. Defaults to `nil`.
    /// - Returns: `true` if registered, `false` otherwise.
    func isRegistered<Product>(_ productType: Product.Type, with name: String? = nil) -> Bool {
        self.isRegistered(productType: productType, with: name)
    }
    
    /// Checks if a registration exists for a given product type, argument type,
    /// with the name defaulting to `nil`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to check.
    ///   - name: An optional name. Defaults to `nil`.
    ///   - argumentType: The type of the argument.
    /// - Returns: `true` if registered, `false` otherwise.
    func isRegistered<Product, Argument: Hashable>(
        _ productType: Product.Type,
        with name: String? = nil,
        and argumentType: Argument.Type
    ) -> Bool {
        self.isRegistered(productType: productType, with: name, and: argumentType)
    }
}
