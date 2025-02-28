//
//  Container.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

// ✅ Registration
// ✅ Resolution
// ✅ InstanceStore
// ✅ Error Handling
// ✅ Behaviors
// ✅ Assemblies
// TODO: Write Unit Tests

/// A dependency injection container that manages registrations and resolves dependencies.
public class Container {
    /// A thread-safe dictionary to store registrations.
    var registrations: ThreadSafeDictionary<RegistrationKey, any Registrable> = .init()
    /// A set to track keys currently being resolved to detect circular dependencies.
    var resolvingKeys: Set<RegistrationKey> = .init()
    /// A thread-safe array to store behaviors.
    var behaviors: ThreadSafeArray<Behavior> = .init()
    
    /// Initializes a new `Container` instance.
    public init() {}
    
    /// Registers an asynchronous factory for a product type.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name for the registration.
    ///   - overridable: Indicates whether the registration can be overridden (default is `true`).
    ///   - block: The asynchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func registerAsync<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        overridable: Bool = true,
        factory block: @escaping (Resolver) async throws -> Product
    ) throws -> any Registrable<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let factory = Factory.async(block)
        let registration = Registration(factory: factory, isOverridable: overridable)
        try assertRegistrationAllowed(productType, name: name, overridable: overridable)
        registrations.insert(registration, for: key)
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        return registration
    }
    
    /// Registers a synchronous factory for a product type.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name for the registration.
    ///   - overridable: Indicates whether the registration can be overridden (default is `true`).
    ///   - block: The synchronous factory closure.
    /// - Returns: The created `Registration` instance.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        overridable: Bool = true,
        factory block: @escaping (Resolver) throws -> Product
    ) throws -> any Registrable<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let factory = Factory.sync(block)
        let registration = Registration(factory: factory, isOverridable: overridable)
        try assertRegistrationAllowed(productType, name: name, overridable: overridable)
        registrations.insert(registration, for: key)
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        return registration
    }
    
    /// Checks if a product type is registered.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to check.
    ///   - name: An optional name for the registration.
    /// - Returns: `true` if the product type is registered, `false` otherwise.
    public func isRegistered<Product>(_ productType: Product.Type, with name: String?) -> Bool {
        let key = RegistrationKey(productType: productType, name: name)
        return registrations.contains(key)
    }
    
    /// Clears all registrations from the container.
    public func clear() {
        registrations.removeAll()
    }
    
    /// Adds a behavior to the container.
    ///
    /// - Parameter behavior: The behavior to add.
    public func add(_ behavior: Behavior) {
        behaviors.append(behavior)
    }
}

extension Container: Resolver {
    /// Resolves a product type synchronously.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration exists, or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    public func resolve<Product>(_ productType: Product.Type, name: String?) throws -> Product {
        defer { removeRegistrationKey(for: productType, with: name) }
        let registration = try findRegistration(for: productType, with: name)
        let product = try registration.resolve(self)
        return product
    }
    
    /// Resolves a product type asynchronously.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration exists, or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    public func resolveAsync<Product>(_ productType: Product.Type, name: String?) async throws -> Product {
        defer { removeRegistrationKey(for: productType, with: name) }
        let registration = try findRegistration(for: productType, with: name)
        let product = try await registration.resolveAsync(self)
        return product
    }
}

extension Container {
    /// Finds a registration for a product type.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to find.
    ///   - name: An optional name for the registration.
    /// - Returns: The found `Registration` instance.
    /// - Throws: `ResolutionError.noRegistrationFound` if no registration exists, or `ResolutionError.circularDependencyDetected` if a circular dependency is detected.
    func findRegistration<Product>(for productType: Product.Type, with name: String?) throws -> Registration<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let result = resolvingKeys.insert(key)
        guard result.inserted else {
            resolvingKeys.removeAll()
            throw ResolutionError.circularDependencyDetected
        }
        guard let registration = registrations.getValue(for: key) as? Registration<Product>
        else { throw ResolutionError.noRegistrationFound }
        return registration
    }
    
    /// Removes a registration key from the resolving keys set.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to remove.
    ///   - name: An optional name for the registration.
    func removeRegistrationKey<Product>(for productType: Product.Type, with name: String?) {
        let key = RegistrationKey(productType: productType, name: name)
        resolvingKeys.remove(key)
    }
    
    /// Validates if a registration already exists for the given product type and name,
    /// throwing an error if a non-overridable registration is found.
    ///
    /// - Parameters:
    ///   - productType: The type of the product being registered.
    ///   - name: An optional name associated with the registration.
    ///   - overridable: A boolean indicating if the new registration is overridable.
    /// - Throws: `RegistrationError.alreadyRegistered` if a non-overridable registration already exists.
    private func assertRegistrationAllowed<Product>(_ productType: Product.Type, name: String?, overridable: Bool) throws {
        // Construct a RegistrationKey to identify the registration.
        let key = RegistrationKey(productType: productType, name: name)
        
        // Attempt to retrieve an existing registration using the key.
        if let existingRegistration = registrations.getValue(for: key) as? Registration<Product> {
            // If an existing registration is found, check if it and the new registration are both overridable.
            // If not, it means we're trying to register something that conflicts with a non-overridable existing registration.
            guard existingRegistration.isOverridable, overridable else {
                // Throw an error indicating that a registration already exists and cannot be overridden.
                throw RegistrationError.alreadyRegistered
            }
        }
        // If no existing registration is found, or if both are overridable, the validation passes.
    }
}
