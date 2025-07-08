//
//  Container+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 5/22/25.
//

import AstrojectCore

/// Provides convenient extension methods for the `Container` protocol,
/// simplifying the registration of asynchronous factories.
///
/// These extensions offer various overloads for the `register` method, allowing you to
/// define asynchronous dependency creation blocks with or without a `Resolver` and/or an `Argument`.
public extension Container {
    /// Registers an asynchronous factory for a product that takes a `Resolver` as an argument.
    ///
    /// This method simplifies registering a dependency whose creation is an asynchronous operation
    /// and might require resolving other dependencies from the container.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: An `async throws` closure that takes a `Resolver` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Resolver) async throws -> Product
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { resolver in
                try await block(resolver)
            })
        )
    }
    
    /// Registers an asynchronous factory for a product that takes no arguments.
    ///
    /// Use this for straightforward asynchronous dependency creation where no `Resolver`
    /// or other arguments are needed within the factory closure itself.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: An `async throws` closure that takes no arguments and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () async throws -> Product
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { _ in
                try await block()
            })
        )
    }
    
    /// Registers an asynchronous factory for a product that requires both a `Resolver` and a specific `Argument`.
    ///
    /// This is useful when the creation of a dependency depends on both the container
    /// itself (to resolve nested dependencies) and a specific, external argument.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required by the factory.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: An `async throws` closure that takes a `Resolver` and an `Argument`,
    ///            then returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Resolver, Argument) async throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with an asynchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { resolver, argument in
                try await block(resolver, argument)
            })
        )
    }
    
    /// Registers an asynchronous factory for a product that takes only a specific `Argument`.
    ///
    /// Use this for asynchronous dependency creation where the product's instance depends
    /// solely on an external argument and does not require resolving other dependencies from the container.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required by the factory.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: An `async throws` closure that takes an `Argument` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Argument) async throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with an asynchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { _, argument in
                try await block(argument)
            })
        )
    }
    
    /// Registers an asynchronous factory for a product that takes no arguments, even when
    /// an `argumentType` is specified.
    ///
    /// This overload is useful when you want to use the argument-specific registration mechanism
    /// (e.g., for clearer API semantics or future extensibility) but the actual factory closure
    /// doesn't directly use the `Resolver` or the `Argument`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument associated with this registration (even if not used in the block).
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: An `async throws` closure that takes no arguments and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () async throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with an asynchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.async { _, _ in
                try await block()
            })
        )
    }
}
