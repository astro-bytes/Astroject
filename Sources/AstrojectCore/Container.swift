//
// Container.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A dependency injection container that manages registrations and resolves dependencies.
public final class Container: @unchecked Sendable {
    /// A thread-safe dictionary to store registrations.
    var registrations: ThreadSafeDictionary<RegistrationKey, any Registrable> = .init()
    /// A thread-safe array to store behaviors.
    var behaviors: ThreadSafeArray<Behavior> = .init()
    /// A thread-safe set to track keys currently being resolved to detect circular dependencies.
    var resolvingKeys: ThreadSafeSet<RegistrationKey> = .init()
    
    /// Initializes a new `Container` instance.
    public init() {}
    
    /// Registers a synchronous factory for a product type.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to register.
    ///     - name: An optional name for the registration.
    ///     - isOverridable: Indicates whether the registration can be overridden (default is `true`).
    ///     - factory: The synchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Create a registration instance with the provided factory and overridable flag.
        let registration = Registration(factory: factory, isOverridable: isOverridable)
        // Assert that the registration is allowed (no conflicting non-overridable registration).
        try assertRegistrationAllowed(productType, name: name, overridable: isOverridable)
        // Insert the registration into the registrations dictionary.
        registrations.insert(registration, for: key)
        // Notify all registered behaviors about the new registration.
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        // Return the created registration.
        return registration
    }
    
    /// Registers a synchronous factory for a product type using a closure.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to register.
    ///     - name: An optional name for the registration.
    ///     - isOverridable: Indicates whether the registration can be overridden (default is `true`).
    ///     - block: The synchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping Factory<Product>.Block
    ) throws -> any Registrable<Product> {
        // Create a factory from the provided closure.
        let factory = Factory(block)
        // Register the product using the created factory.
        return try self.register(productType, name: name, isOverridable: isOverridable, factory: factory)
    }
    
    /// Registers an asynchronous factory for a product type using a closure.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to register.
    ///     - name: An optional name for the registration.
    ///     - isOverridable: Indicates whether the registration can be overridden (default is `true`).
    ///     - block: The asynchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        block: @escaping () async throws -> Product
    ) throws -> any Registrable<Product> {
        // Create a factory that wraps the asynchronous closure.
        let factory = Factory { _ in try await block() }
        // Register the product using the created factory.
        return try self.register(productType, name: name, isOverridable: isOverridable, factory: factory)
    }
    
    /// Checks if a product type is registered.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to check.
    ///     - name: An optional name for the registration.
    /// - Returns: `true` if the product type is registered, `false` otherwise.
    public func isRegistered<Product>(_ productType: Product.Type, with name: String?) -> Bool {
        // Create a key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Check if the registrations dictionary contains the key.
        return registrations.contains(key)
    }
    
    /// Clears all registrations from the container.
    public func clear() {
        // Remove all registrations from the dictionary.
        registrations.removeAll()
    }
    
    /// Adds a behavior to the container.
    ///
    /// - Parameter behavior: The behavior to add.
    public func add(_ behavior: Behavior) {
        // Append the behavior to the behaviors array.
        behaviors.append(behavior)
    }
}

extension Container: Resolver {
    /// Resolves a product type synchronously.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to resolve.
    ///     - name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration exists,
    /// or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    public func resolve<Product>(_ productType: Product.Type, name: String?) async throws -> Product {
        // Ensure the resolving key is removed after resolution.
        defer { removeRegistrationKey(for: productType, with: name) }
        // Find the registration for the product type.
        let registration = try findRegistration(for: productType, with: name)
        // Resolve the product using the registration.
        let product = try await registration.resolve(self)
        // Return the resolved product.
        return product
    }
}

extension Container {
    /// Finds a registration for a product type.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to find.
    ///     - name: An optional name for the registration.
    /// - Returns: The found `Registration` instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration
    /// exists, or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    func findRegistration<Product>(for productType: Product.Type, with name: String?) throws -> Registration<Product> {
        // Create a key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Insert the key into resolvingKeys to detect circular dependencies.
        guard resolvingKeys.insert(key) else {
            // If the key is already in resolvingKeys, a circular dependency is detected.
            resolvingKeys.removeAll()
            throw AstrojectError.circularDependencyDetected
        }
        // Retrieve the registration from the registrations dictionary.
        guard let registration = registrations.getValue(for: key) as? Registration<Product> else {
            // If no registration is found, throw an error.
            throw AstrojectError.noRegistrationFound
        }
        // Return the found registration.
        return registration
    }
    
    /// Removes a registration key from the resolving keys set.
    ///
    /// - Parameters:
    ///     - productType: The type of the product to remove.
    ///     - name: An optional name for the registration.
    func removeRegistrationKey<Product>(for productType: Product.Type, with name: String?) {
        // Create a key for the registration.
        let key = RegistrationKey(productType: productType, name: name)
        // Remove the key from the resolvingKeys set.
        resolvingKeys.remove(key)
    }
    
    /// Validates if a registration already exists for the given product type and name,
    /// throwing an error if a non-overridable registration is found.
    ///
    /// - Parameters:
    ///     - productType: The type of the product being registered.
    ///     - name: An optional name associated with the registration.
    ///     - overridable: A boolean indicating if the new registration is overridable.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    func assertRegistrationAllowed<Product>(_ productType: Product.Type, name: String?, overridable: Bool) throws {
        // Construct a RegistrationKey to identify the registration.
        let key = RegistrationKey(productType: productType, name: name)
        
        // Attempt to retrieve an existing registration using the key.
        if let existingRegistration = registrations.getValue(for: key) as? Registration<Product> {
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
