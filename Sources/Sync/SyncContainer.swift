//
//  SyncContainer.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
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
    ///  A dictionary to store the dependency resolution graph for each thread.
    ///  This is used to detect circular dependencies.
    private(set) var resolvingGraphs: [ObjectIdentifier: [RegistrationKey]] = [:]
    
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
        let key = RegistrationKey(productType: productType, name: name)
        // Create a registration instance that encapsulates the provided factory and the overridable setting.
        let registration = Registration(
            factory: factory,
            isOverridable: isOverridable,
            instance: Graph<Product>()
        )
        // Before adding the new registration, ensure that it is allowed based on existing registrations.
        try assertRegistrationAllowed(productType, name: name, overridable: isOverridable)
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
        name: String? = nil,
        argument: Argument.Type,
        isOverridable: Bool = true,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration, including the argument type.
        let key = RegistrationKey(productType: productType, name: name, argumentType: Argument.self)
        // Create a registration instance that holds the factory, the overridable setting, and the argument type.
        let registration = RegistrationWithArgument(
            factory: factory,
            isOverridable: isOverridable,
            argumentType: Argument.self,
            instance: Graph<Product>()
        )
        // Ensure that this registration is allowed based on any existing registrations.
        try assertRegistrationAllowed(productType, name: name, overridable: isOverridable)
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
        let key = RegistrationKey(productType: productType, name: name)
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
        let key = RegistrationKey(productType: productType, name: name, argumentType: argumentType)
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
        // Check current depth
        let currentDepth = Context.current.depth
        
        if currentDepth == 0 {
            // Top-level resolution: create fresh context with new graph ID
            return try Context.$current.withValue(Context.fresh()) {
                try internalResolve(type, name: name)
            }
        } else {
            // Nested resolution: increment depth but keep same graphID
            let nextContext = Context.current.next()
            return try Context.$current.withValue(nextContext) {
                try internalResolve(type, name: name)
            }
        }
    }
    
    public func resolve<Product, Argument: Hashable>(
        productType type: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        // Check current depth
        let currentDepth = Context.current.depth
        
        if currentDepth == 0 {
            // Top-level resolution: create fresh context with new graph ID
            return try Context.$current.withValue(Context.fresh()) {
                try internalResolve(type, name: name, argument: argument)
            }
        } else {
            // Nested resolution: increment depth but keep same graphID
            let nextContext = Context.current.next()
            return try Context.$current.withValue(nextContext) {
                try internalResolve(type, name: name, argument: argument)
            }
        }
    }
    
    public func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product {
        fatalError("Not Supported")
    }
    
    public func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        fatalError("Not Supported")
    }
}

// MARK: Helper Functions
extension SyncContainer {
    /// Internal resolution method for products without arguments.
    ///
    /// This method handles the core logic for resolving a product, including
    /// checking for circular dependencies and interacting with the `Context`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    /// - Returns: An instance of the resolved `Product`.
    /// - Throws: `AstrojectError.circularDependencyDetected` if a circular dependency is found,
    ///           or `AstrojectError.noRegistrationFound` if no suitable registration exists.
    func internalResolve<Product>(
        _ productType: Product.Type,
        name: String?
    ) throws -> Product {
        let key = RegistrationKey(productType: productType, name: name)
        var graph = getGraph()
        
        // Check for circular dependency in THIS thread's stack
        if graph.contains(key) {
            throw AstrojectError.cyclicDependency(type: "\(productType)", name: name)
        }
        
        // Push onto THIS thread's stack
        graph.append(key)
        updateGraph(graph)
        defer {
            // Pop from THIS thread's stack
            graph.removeLast()
            updateGraph(graph)
        }
        // Find the registration for the requested product type and name.
        let registration = try findRegistration(for: productType, with: name)
        // Resolve the product using the found registration and the current resolver (self).
        let product = try registration.resolve(self)
        // Return the resolved instance of the product.
        return product
    }
    
    /// Internal resolution method for products that require an argument.
    ///
    /// This method extends the resolution logic to handle factories that need
    /// an additional argument for instantiation, including circular dependency detection.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    ///   - argument: The argument required by the product's factory.
    /// - Returns: An instance of the resolved `Product`.
    /// - Throws: `AstrojectError.circularDependencyDetected` if a circular dependency is found,
    ///           or `AstrojectError.noRegistrationFound` if no suitable registration exists.
    func internalResolve<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        let key = RegistrationKey(productType: productType, name: name, argumentType: Argument.self)
        
        var graph = getGraph()
        // Check for circular dependency in THIS thread's stack
        if graph.contains(key) {
            throw AstrojectError.cyclicDependency(type: "\(productType)", name: name)
        }
        
        // Push onto THIS thread's stack
        graph.append(key)
        updateGraph(graph)
        defer {
            // Pop from THIS thread's stack
            graph.removeLast()
            updateGraph(graph)
        }
        
        // Find the registration for the product type, name, and the type of the argument.
        let registration = try findRegistration(for: productType, with: name, argument: argument)
        // Resolve the product by calling the registration's resolve method with the resolver and the argument.
        let product = try registration.resolve(self, argument: argument)
        // Return the resolved product instance.
        return product
    }
    
    /// Finds a registration for a product type.
    ///
    /// - parameter productType: The type of the product to find the registration for.
    /// - parameter name: An optional name associated with the registration.
    /// - Returns: The found `Registration` instance.
    /// - Throws: `AstrojectError.noRegistrationFound` if no registration exists for the given
    ///  `productType` and `name`.
    func findRegistration<Product>(
        for productType: Product.Type,
        with name: String?
    ) throws -> Registration<Product> {
        // Create a key to look up the registration in the dictionary.
        let key = RegistrationKey(productType: productType, name: name)
        // Access the registrations dictionary in a thread-safe manner to retrieve the registration.
        let registration = serialQueue.sync {
            registrations[key] as? Registration<Product>
        }
        // If no registration is found for the given key, throw an error.
        guard let registration else {
            throw AstrojectError.noRegistrationFound(type: "\(productType)", name: name)
        }
        
        // Return the found registration.
        return registration
    }
    
    /// Finds a registration for a product type that requires a specific argument.
    ///
    /// - parameter productType: The type of the product to find the registration for.
    /// - parameter name: An optional name associated with the registration.
    /// - parameter argument: The specific argument instance used to identify the registration.
    /// - Returns: The found `RegistrationWithArgument` instance.
    /// - Throws: `AstrojectError.noRegistrationFound` if no matching registration is found.
    func findRegistration<Product, Argument>(
        for productType: Product.Type,
        with name: String?,
        argument: Argument
    ) throws -> RegistrationWithArgument<Product, Argument> {
        // Create the key used to find the registration, including the argument type.
        let key = RegistrationKey(productType: productType, name: name, argumentType: Argument.self)
        
        // Access the registrations dictionary in a thread-safe manner.
        let registration = serialQueue.sync {
            // Attempt to cast the registration to the specific type that handles arguments.
            registrations[key] as? RegistrationWithArgument<Product, Argument>
        }
        
        // If no registration is found, throw an error indicating that.
        guard let registration else {
            let argumentType = type(of: argument)
            let spacing = name == nil ? "" : " "
            let nameAndArgument = name ?? "" + "\(spacing)argument of type: \(argumentType)"
            throw AstrojectError.noRegistrationFound(
                type: "\(productType)",
                name: nameAndArgument)
        }
        
        // Return the found registration.
        return registration
    }
    
    /// Validates if a registration already exists for the given product type and name,
    /// throwing an error if a non-overridable registration is found.
    ///
    /// - parameter productType: The type of the product being registered.
    /// - parameter name: An optional name associated with the registration.
    /// - parameter overridable: A boolean indicating if the new registration is overridable.
    /// - Throws: `AstrojectError.alreadyRegistered` if a non-overridable registration already exists.
    func assertRegistrationAllowed<Product>(_ productType: Product.Type, name: String?, overridable: Bool) throws {
        // Construct a RegistrationKey to identify the registration.
        let key = RegistrationKey(productType: productType, name: name)
        
        // Attempt to retrieve an existing registration using the key.
        let existingRegistration = serialQueue.sync {
            registrations[key] as? Registration<Product>
        }
        
        // Check if an existing registration was found.
        if let existingRegistration {
            // If an existing registration is found, check if both the existing registration and
            // the new one are overridable.
            // If the existing one is not overridable, we should not allow the new registration.
            guard existingRegistration.isOverridable, overridable else {
                // Throw an error indicating that a registration already exists and cannot be overridden.
                throw AstrojectError.alreadyRegistered(type: "\(productType)", name: name)
            }
        }
        // If no existing registration is found, or if both are overridable, the validation passes.
    }
    
    /// Retrieves the dependency resolution graph for the current thread.
    ///
    /// - Returns: The dependency resolution graph for the current thread.
    func getGraph() -> [RegistrationKey] {
        let thread = Thread.current
        let threadIdentifier = ObjectIdentifier(thread)
        return serialQueue.sync {
            if let graph = resolvingGraphs[threadIdentifier] {
                return graph
            } else {
                let newGraph: [RegistrationKey] = []
                resolvingGraphs[threadIdentifier] = newGraph
                return newGraph
            }
        }
    }
    
    /// Updates the dependency resolution graph for the current thread.
    ///
    /// - parameter graph: The updated dependency resolution graph.
    func updateGraph(_ graph: [RegistrationKey]) {
        let thread = Thread.current
        let threadIdentifier = ObjectIdentifier(thread)
        serialQueue.sync {
            resolvingGraphs[threadIdentifier] = graph
        }
    }
}
