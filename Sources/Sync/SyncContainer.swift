//  SyncContainer.swift
//  Astroject
//
//  Created by Porter McGady on 5/21/25.
//

import Foundation
import AstrojectCore

/// A dependency injection container that manages registrations and resolves dependencies.
public final class SyncContainer: Container, @unchecked Sendable {
    /// A serial dispatch queue used to ensure thread-safe access to the container's internal state.
    ///  This prevents race conditions when multiple threads try to access or modify the `registrations` dictionary.
    private let serialQueue: DispatchQueue = .init(label: "com.astrobytes.astroject.sync.container")
    /// A dictionary that stores the registrations of different product types. The key is a `RegistrationKey`
    /// that uniquely identifies a registration, and the value is the corresponding `Registrable` instance.
    ///  `Registrable` encapsulates the factory and other registration-related information.
    private(set) var registrations: [RegistrationKey: any Registrable] = [:]
    /// An array to hold different behaviors that can observe and interact with the container's lifecycle,
    /// such as when registrations are added.  Behaviors can be used for cross-cutting concerns
    /// like logging, validation, or modifying registrations.
    private(set) var behaviors: [Behavior] = []
    
    /// Initializes a new `Container` instance.
    public init() {}
    
    @discardableResult
    public func register<Product>(
        productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration based on the product type and optional name.
        let key = RegistrationKey(factory: factory, name: name)
        // Create a registration instance that encapsulates the provided factory and the overridable setting.
        let registration = Registration(
            factory: factory,
            isOverridable: isOverridable,
            instanceType: Graph.self
        )
        // Before adding the new registration, ensure that it is allowed based on existing registrations.
        try assertRegistrationAllowed(for: key, overridable: isOverridable)
        // Perform the actual registration by adding the key-registration pair to the dictionary
        // within a synchronized block to ensure thread safety.
        serialQueue.sync {
            registrations[key] = registration
        }
        // Notify all registered behaviors that a new registration has been added. This allows behaviors
        // to react to registration events, such as logging or performing additional setup.
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        // Return the newly created registration.
        return registration
    }
    
    @discardableResult
    public func register<Product, Argument: Hashable>(
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration, including the argument type.
        let key = RegistrationKey(factory: factory, name: name)
        // Create a registration instance that holds the factory, the overridable setting, and the argument type.
        let registration = RegistrationWithArgument(
            factory: factory,
            isOverridable: isOverridable,
            instanceType: Graph.self
        )
        // Ensure that this registration is allowed based on any existing registrations.
        try assertRegistrationAllowed(for: key, overridable: isOverridable)
        // Add the registration to the dictionary in a thread-safe manner.
        serialQueue.sync {
            registrations[key] = registration
        }
        // Notify all registered behaviors about the new registration.
        serialQueue.sync {
            behaviors.forEach {
                $0.didRegister(type: productType, to: self, as: registration, with: name)
            }
        }
        // Return the created registration.
        return registration
    }
    
    public func isRegistered<Product>(productType: Product.Type, with name: String?) -> Bool {
        // Create a key representing the registration to check.
        let key = RegistrationKey(
            factoryType: Factory<Product, Resolver>.SyncBlock.self,
            productType: productType,
            name: name
        )
        // Check if this key exists in the registrations dictionary.
        return serialQueue.sync {
            registrations.keys.contains(key)
        }
    }
    
    public func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool {
        let key = RegistrationKey(
            factoryType: Factory<Product, (Resolver, Argument)>.SyncBlock.self,
            productType: productType,
            argumentType: argumentType,
            name: name
        )
        return serialQueue.sync {
            registrations.keys.contains(key)
        }
    }
    
    public func clear() {
        // Remove all key-value pairs from the registrations dictionary in a thread-safe way.
        serialQueue.sync {
            registrations.removeAll()
        }
    }
    
    public func add(_ behavior: Behavior) {
        // Append the provided behavior to the list of registered behaviors.
        serialQueue.sync {
            behaviors.append(behavior)
        }
    }
}

// MARK: Conform to Resolver
extension SyncContainer: Resolver {
    public func resolve<Product>(
        productType type: Product.Type,
        name: String?
    ) throws -> Product {
        try manageContext {
            try initiateResolution(type, name: name, argument: Never?(nil))
        }
    }
    
    public func resolve<Product, Argument: Hashable>(
        productType type: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        try manageContext {
            try initiateResolution(type, name: name, argument: argument)
        }
    }
    
    public func resolve<Product>(
        productType type: Product.Type,
        name: String?
    ) async throws -> Product {
        try manageContext {
            try initiateResolution(type, name: name, argument: Never?(nil))
        }
    }
    
    public func resolve<Product, Argument: Hashable>(
        productType type: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        try manageContext {
            try initiateResolution(type, name: name, argument: argument)
        }
    }
}

// MARK: Helper Functions
extension SyncContainer {
    /// Initiates the resolution process for a product, handling key creation,
    /// circular dependency checks, and context management before delegating
    /// to the actual registration lookup and resolution.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    ///   - argument: An optional argument value required by the product's factory.
    ///   - argumentType: The *type* of the argument. Use `Void.self` if no argument is expected.
    /// - Returns: An instance of the resolved `Product`.
    /// - Throws: `AstrojectError.cyclicDependency` if a circular dependency is found,
    ///           or `AstrojectError.noRegistrationFound` if no suitable registration exists,
    ///           or any error thrown by the product's factory.
    func initiateResolution<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String?,
        argument: Argument? = nil
    ) throws -> Product {
        let key: RegistrationKey
        
        if argument != nil {
            // Case: Resolving with an argument
            key = RegistrationKey(
                factoryType: Factory<Product, (Resolver, Argument)>.SyncBlock.self,
                productType: productType,
                argumentType: Argument.self, // Still need the type for the key
                name: name
            )
        } else {
            // Case: Resolving without an argument
            key = RegistrationKey(
                factoryType: Factory<Product, Resolver>.SyncBlock.self,
                productType: productType,
                name: name
            )
        }
        
        let graph = Context.current.graph
        
        // Check for circular dependency
        if graph.contains(key) {
            throw AstrojectError.cyclicDependency(key: graph.first ?? key, path: graph)
        }
        
        // Push onto the task-local resolution path
        return try Context.$current.withValue(Context.current.push(key)) {
            try findAndResolve(for: key, with: argument)
        }
    }
    
    /// Looks up the registration for a given key and resolves the product.
    /// This function handles the type casting and calls the appropriate resolve method
    /// based on whether an argument is provided.
    ///
    /// - Parameters:
    ///   - key: The `RegistrationKey` to look up.
    ///   - argument: An optional argument value to pass to the factory if it's an argumented registration.
    /// - Returns: The resolved product instance.
    /// - Throws: `AstrojectError.noRegistrationFound` if the registration doesn't exist
    ///           or if there's a type mismatch during casting.
    func findAndResolve<Product, Argument: Hashable>(
        for key: RegistrationKey,
        with argument: Argument?
    ) throws -> Product {
        // Helper function to notify behaviors after successful resolution.
        func didRegister(_ registration: any Registrable<Product>) {
            serialQueue.sync {
                behaviors.forEach {
                    $0.didResolve(
                        type: Product.self,
                        to: self,
                        as: registration,
                        with: key.name
                    )
                }
            }
        }
        
        // Retrieve registration based on the key
        let registration = serialQueue.sync {
            registrations[key]
        }
        
        guard let registration else {
            throw AstrojectError.noRegistrationFound(key: key)
        }
        
        // Now, cast and resolve based on whether an argument was provided
        if let argumentValue = argument {
            // If an argument was provided, try to resolve it as an argumented registration
            guard let registration = registration as? RegistrationWithArgument<Product, Argument> else {
                // This means a registration for the product type and name exists,
                // but it wasn't registered with the expected argument type.
                throw AstrojectError.noRegistrationFound(key: key)
            }
            defer { didRegister(registration) }
            return try registration.resolve(self, argument: argumentValue)
        } else {
            // If no argument was provided, try to resolve it as a non-argumented registration
            guard let registration = registration as? Registration<Product> else {
                // Similar to above, registration exists but was actually registered with an argument.
                throw AstrojectError.noRegistrationFound(key: key)
            }
            defer { didRegister(registration) }
            return try registration.resolve(self)
        }
    }
    
    /// A generic helper function to manage the `Context` for resolution calls.
    /// It handles creating a fresh context for top-level resolutions or
    /// advancing the context for nested resolutions.
    ///
    /// - Parameter body: A throwing closure that performs the actual resolution logic.
    /// - Returns: The resolved product instance.
    /// - Throws: Any error thrown by the `body` closure.
    func manageContext<T>(body: () throws -> T) throws -> T {
        let currentContext = Context.current
        
        if currentContext.depth == 0 {
            // Top-level resolution: create fresh context with new graph ID and empty path
            return try Context.$current.withValue(Context.fresh()) {
                try body()
            }
        } else {
            // Nested resolution: increment depth but keep same graphID and continue path
            let nextContext = currentContext.next()
            return try Context.$current.withValue(nextContext) {
                try body()
            }
        }
    }
    
    /// Asserts whether a new registration is allowed based on existing registrations and their overridability.
    ///
    /// - Parameters:
    ///   - key: The `RegistrationKey` for the new registration.
    ///   - overridable: A boolean indicating if the new registration is overridable.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration for the same
    ///           key already exists, or if an existing overridable registration is found but the new registration is
    ///           not marked as overridable.
    func assertRegistrationAllowed(for key: RegistrationKey, overridable: Bool) throws {
        // Attempt to retrieve an existing registration using the key.
        let existingRegistration = serialQueue.sync {
            registrations[key]
        }
        
        // Check if an existing registration was found.
        if let existingRegistration {
            // If an existing registration is found, check if both the existing registration and
            // the new one are overridable.
            // If the existing one is not overridable, we should not allow the new registration.
            guard existingRegistration.isOverridable, overridable else {
                // Throw an error indicating that a registration already exists and cannot be overridden.
                throw AstrojectError.alreadyRegistered(key: key)
            }
        }
        // If no existing registration is found, or if both are overridable, the validation passes.
    }
}
