//
//  Container+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 5/22/25.
//

import AstrojectCore

/// Provides convenient extension methods for the `Container` protocol,
/// simplifying the registration of synchronous factories.
///
/// These extensions offer various overloads for the `register` method, allowing you to
/// define synchronous dependency creation blocks with or without a `Resolver` and/or an `Argument`.
public extension Container {
    /// Registers a synchronous factory for a product that takes a `Resolver` as an argument.
    ///
    /// This method simplifies registering a dependency whose creation is a synchronous operation
    /// and might require resolving other dependencies from the container.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: A `throws` closure that takes a `Resolver` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Resolver) throws -> Product
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.sync { resolver in
                try block(resolver)
            })
        )
    }
    
    /// Registers a synchronous factory for a product that takes no arguments.
    ///
    /// Use this for straightforward synchronous dependency creation where no `Resolver`
    /// or other arguments are needed within the factory closure itself.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: A `throws` closure that takes no arguments and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () throws -> Product
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.sync { _ in
                try block()
            })
        )
    }
    
    /// Registers a synchronous factory for a product that requires both a `Resolver` and a specific `Argument`.
    ///
    /// This is useful when the creation of a dependency depends on both the container
    /// itself (to resolve nested dependencies) and a specific, external argument.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required by the factory.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: A `throws` closure that takes a `Resolver` and an `Argument`,
    ///            then returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Resolver, Argument) throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with a synchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.sync { resolver, argument in
                try block(resolver, argument)
            })
        )
    }
    
    /// Registers a synchronous factory for a product that takes only a specific `Argument`.
    ///
    /// Use this for synchronous dependency creation where the product's instance depends
    /// solely on an external argument and does not require resolving other dependencies from the container.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required by the factory.
    ///   - name: An optional name to differentiate this registration. Defaults to `nil`.
    ///   - isOverridable: A boolean indicating if this registration can be overridden. Defaults to `true`.
    ///   - block: A `throws` closure that takes an `Argument` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping (Argument) throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with a synchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.sync { _, argument in
                try block(argument)
            })
        )
    }
    
    /// Registers a synchronous factory for a product that takes no arguments, even when an `argumentType` is specified.
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
    ///   - block: A `throws` closure that takes no arguments and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance for further configuration.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with a synchronous `Factory` created from the block.
        return try self.register(
            productType: productType,
            argumentType: argumentType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(.sync { _, _ in
                try block()
            })
        )
    }
}
