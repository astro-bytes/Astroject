//
// Container.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A dependency injection container that manages registrations and resolves dependencies.
public final class Container: @unchecked Sendable {
    // TODO: Comment
    let serialQueue: DispatchQueue = .init(label: "astroject.container")
    // TODO: Comment
    var registrations: [RegistrationKey: any Registrable] = [:]
    // TODO: Comment
    var behaviors: [Behavior] = []
    
    /// Initializes a new `Container` instance.
    public init() {}
    
    /// Registers a synchronous factory for a product type.
    ///
    /// - parameter productType: The type of the product to register.
    /// - parameter name: An optional name for the registration.
    /// - parameter isOverridable: Indicates whether the registration can be overridden (default is `true`).
    /// - parameter factory: The synchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Create a registration instance with the provided factory and overridable flag.
        let registration = Registration(factory: factory, isOverridable: isOverridable)
        // Assert that the registration is allowed (no conflicting non-overridable registration).
        try assertRegistrationAllowed(productType, name: name, overridable: isOverridable)
        // Insert the registration into the registrations dictionary.
        serialQueue.sync {
            registrations[key] = registration
        }
        // Notify all registered behaviors about the new registration.
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        // Return the created registration.
        return registration
    }
    
    // TODO: Comment
    @discardableResult
    public func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration.
        let key = RegistrationKey(productType: productType, name: name, argumentType: Argument.self)
        // Create a registration instance with the provided factory and overridable flag.
        let registration = RegistrationWithArgument(
            factory: factory,
            isOverridable: isOverridable,
            argumentType: Argument.self
        )
        // Assert that the registration is allowed (no conflicting non-overridable registration).
        try assertRegistrationAllowed(productType, name: name, overridable: isOverridable)
        // Insert the registration into the registrations dictionary.
        serialQueue.sync {
            registrations[key] = registration
        }
        // Notify all registered behaviors about the new registration.
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        // Return the created registration.
        return registration
    }
    
    /// Checks if a product type is registered.
    ///
    /// - parameter productType: The type of the product to check.
    /// - parameter name: An optional name for the registration.
    /// - Returns: `true` if the product type is registered, `false` otherwise.
    public func isRegistered<Product>(_ productType: Product.Type, with name: String?) -> Bool {
        // Create a key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Check if the registrations dictionary contains the key.
        return registrations.keys.contains(key)
    }
    
    /// Clears all registrations from the container.
    public func clear() {
        // Remove all registrations from the dictionary.
        serialQueue.sync {
            registrations.removeAll()
        }
    }
    
    /// Adds a behavior to the container.
    ///
    /// - parameter behavior: The behavior to add.
    public func add(_ behavior: Behavior) {
        // Append the behavior to the behaviors array.
        behaviors.append(behavior)
    }
}

// MARK: Register Helper Functions
public extension Container {
    /// Registers a synchronous factory for a product type using a closure.
    ///
    /// - parameter productType: The type of the product to register.
    /// - parameter name: An optional name for the registration.
    /// - parameter isOverridable: Indicates whether the registration can be overridden (default is `true`).
    /// - parameter block: The synchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping Factory<Product, Resolver>.Block
    ) throws -> any Registrable<Product> {
        // Register the product using the created factory.
        return try self.register(
            productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory(block)
        )
    }
    
    /// Registers an asynchronous factory for a product type using a closure.
    ///
    /// - parameter productType: The type of the product to register.
    /// - parameter name: An optional name for the registration.
    /// - parameter isOverridable: Indicates whether the registration can be overridden (default is `true`).
    /// - parameter block: The asynchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () async throws -> Product
    ) throws -> any Registrable<Product> {
        // Register the product using the created factory.
        return try self.register(
            productType,
            name: name,
            isOverridable: isOverridable,
            factory: Factory<Product, Resolver> { _ in try await block() }
        )
    }
}

// MARK: Register with Argument Helper Functions
public extension Container {
    // TODO: Comment
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        block: @escaping Factory<Product, (Resolver, Argument)>.Block
    ) throws -> any Registrable<Product> {
        // Register the product using the created factory.
        return try self.register(
            productType,
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
        block: @escaping (Resolver, Argument) async throws -> Product
    ) throws -> any Registrable<Product> {
        // Register the product using the created factory.
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
}

// MARK: Conform to Resolver
extension Container: Resolver {
    /// Resolves a product type synchronously.
    ///
    /// - parameter  productType: The type of the product to resolve.
    /// - parameter name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration exists,
    /// or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    public func resolve<Product>(
        _ productType: Product.Type,
        name: String?
    ) async throws -> Product {
        // Find the registration for the product type.
        let registration = try findRegistration(for: productType, with: name)
        // Resolve the product using the registration.
        let product = try await registration.resolve(self)
        // Return the resolved product.
        return product
    }
    
    // TODO: Comment
    public func resolve<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        // Find the registration for the product type.
        let registration = try findRegistration(for: productType, with: name, argument: argument)
        // Resolve the product using the registration.
        let product = try await registration.resolve(self, argument: argument)
        // Return the resolved product.
        return product
    }
}

// MARK: Helper Functions
extension Container {
    /// Finds a registration for a product type.
    ///
    /// - parameter productType: The type of the product to find.
    /// - parameter name: An optional name for the registration.
    /// - Returns: The found `Registration` instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration
    /// exists, or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    func findRegistration<Product>(
        for productType: Product.Type,
        with name: String?
    ) throws -> Registration<Product> {
        // Create a key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Retrieve the registration from the registrations dictionary.
        let registration = serialQueue.sync {
            registrations[key] as? Registration<Product>
        }
        guard let registration else {
            // If no registration is found, throw an error.
            throw AstrojectError.noRegistrationFound
        }
            
        // Return the found registration.
        return registration
    }
    
    // TODO: Comment
    func findRegistration<Product, Argument>(
        for productType: Product.Type,
        with name: String?,
        argument: Argument
    ) throws -> RegistrationWithArgument<Product, Argument> {
        let key = RegistrationKey(productType: productType, name: name, argumentType: Argument.self)
        
        let registration = serialQueue.sync {
            registrations[key] as? RegistrationWithArgument<Product, Argument>
        }
        
        guard let registration else {
            throw AstrojectError.noRegistrationFound
        }
        
        return registration
    }
    
    /// Validates if a registration already exists for the given product type and name,
    /// throwing an error if a non-overridable registration is found.
    ///
    /// - parameter productType: The type of the product being registered.
    /// - parameter name: An optional name associated with the registration.
    /// - parameter overridable: A boolean indicating if the new registration is overridable.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    func assertRegistrationAllowed<Product>(_ productType: Product.Type, name: String?, overridable: Bool) throws {
        // Construct a RegistrationKey to identify the registration.
        let key = RegistrationKey(productType: productType, name: name)
        
        // Attempt to retrieve an existing registration using the key.
        let existingRegistration = serialQueue.sync {
            registrations[key] as? Registration<Product>
        }
        
        if let existingRegistration {
            // If an existing registration is found, check if it
            // and the new registration are both overridable.
            // If not, it means we're trying to register something that
            // conflicts with a non-overridable existing registration.
            guard existingRegistration.isOverridable, overridable else {
                // Throw an error indicating that a registration already exists and cannot be overridden.
                throw AstrojectError.alreadyRegistered(type: "\(productType)", name: name)
            }
        }
        // If no existing registration is found, or if both are overridable, the validation passes.
    }
}
