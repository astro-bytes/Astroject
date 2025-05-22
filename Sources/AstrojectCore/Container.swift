//
//  Container.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation

// TODO: Comment
public protocol Container: Resolver {
    // TODO: Comment
    @discardableResult
    func register<Product>(
        productType: Product.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product>
    
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument.Type,
        isOverridable: Bool,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product>
    
    // TODO: Comment
    func isRegistered<Product>(productType: Product.Type, with name: String?) -> Bool
    
    // TODO: Comment
    func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool
    
    // TODO: Comment
    func clear()
    
    // TODO: Comment
    func add(_ behavior: Behavior)
}

// TODO: Comment
public extension Container {
    // TODO: Comment
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
    
    // TODO: Comment
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: Factory<Product, Resolver>.Block
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(block)
        )
    }
    
    // TODO: Comment
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
            factory: Factory<Product, (Resolver)> { resolver in
                try await block(resolver)
            }
        )
    }
    
    // TODO: Comment
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
            factory: Factory<Product, (Resolver)> { _ in
                try await block()
            }
        )
    }
    
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        block: Factory<Product, (Resolver, Argument)>.Block
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            argument: argument,
            isOverridable: isOverridable,
            factory: Factory(block)
        )
    }
    
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        try self.register(
            productType: productType,
            name: name,
            argument: argument,
            isOverridable: isOverridable,
            factory: factory
        )
    }
    
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        block: @escaping (Resolver, Argument) async throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with an asynchronous `Factory` created from the block.
        return try self.register(
            productType,
            name: name,
            argument: argument,
            isOverridable: isOverridable,
            factory: Factory<Product, (Resolver, Argument)> { resolver, argument in
                try await block(resolver, argument)
            }
        )
    }
    
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        block: @escaping (Argument) async throws -> Product
    ) throws -> any Registrable<Product> {
        // Call the main `register` method with an asynchronous `Factory` created from the block.
        return try self.register(
            productType,
            name: name,
            argument: argument,
            isOverridable: isOverridable,
            factory: Factory<Product, (Resolver, Argument)> { _, argument in
                try await block(argument)
            }
        )
    }
    
    // TODO: Comment
    func isRegistered<Product>(_ productType: Product.Type, with name: String? = nil) -> Bool {
        self.isRegistered(productType: productType, with: name)
    }
    
    // TODO: Comment
    func isRegistered<Product, Argument: Hashable>(
        _ productType: Product.Type,
        with name: String? = nil,
        and argumentType: Argument.Type
    ) -> Bool {
        self.isRegistered(productType: productType, with: name, and: argumentType)
    }
}
