//
//  AsyncContainer.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation
import AstrojectCore

/// A dependency injection container that manages registrations and resolves dependencies asynchronously.
///
/// `AsyncContainer` provides methods for registering factories for different product types,
/// and then resolving instances of these products. It handles both dependencies without arguments
/// and those requiring an argument for resolution. It also includes thread-safety mechanisms
/// using a serial dispatch queue and supports behaviors to extend its functionality.
public final class AsyncContainer: Container, Assemblable, @unchecked Sendable {
    /// A serial dispatch queue used to ensure thread-safe access to the container's internal state.
    /// This prevents race conditions when multiple threads try to access or modify the `registrations` dictionary.
    private let serialQueue: DispatchQueue = .init(label: "com.astrobytes.astroject.async.container")
    /// A dictionary that stores the registrations of different product types. The key is a `RegistrationKey`
    /// that uniquely identifies a registration, and the value is the corresponding `Registrable` instance.
    /// `Registrable` encapsulates the factory and other registration-related information.
    private(set) var registrations: [RegistrationKey: any Registrable] = [:]
    /// An array to hold different behaviors that can observe and interact with the container's lifecycle,
    /// such as when registrations are added. Behaviors can be used for cross-cutting concerns
    /// like logging, validation, or modifying registrations.
    private(set) var behaviors: [Behavior] = []
    /// Records every registration, for `registrationReport()`.
    private let recorder = RegistrationRecorder()
    
    public private(set) var assembler: Assembler?
    
    /// `AsyncContainer` only supports `async` resolution from inside factories.
    public var resolutionMode: ResolutionMode { .async }
    
    /// Initializes a new container with an optional assembler.
    ///
    /// - Parameter createAssembler: A Boolean flag indicating whether to automatically
    ///   create and assign an `Assembler` to this container. Defaults to `false`.
    ///
    /// If `createAssembler` is `true`, a new `Assembler` is created with this container
    /// as its owner. If `false`, the container starts without an assembler and one
    /// can be assigned later.
    public init(createAssembler: Bool = false) {
        guard createAssembler else { return }
        self.assembler = Assembler(container: self)
    }

    /// Initializes a new container and sets up an `Assembler` with the provided assemblies.
    ///
    /// - Parameters:
    ///   - environment: The environment the app is running in. Assemblies whose `environments`
    ///     leave it out are skipped. Defaults to `nil`, which runs every assembly.
    ///   - assemblies: An array of `Assembly` objects used to configure the assembler.
    ///
    /// - Throws: Any error thrown by the `Assembler` initializer if the assembly process fails.
    ///
    /// This initializer automatically creates an `Assembler` for the container and
    /// immediately attempts to assemble it using the provided assemblies.
    public init(environment: AstrojectEnvironment? = nil, assemblies: [Assembly]) throws {
        self.assembler = try Assembler(container: self, environment: environment, assemblies: assemblies)
    }
    
    @discardableResult
    public func register<Product>(
        productType: Product.Type,
        name: String? = nil,
        factory: Factory<Product, Resolver>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration.
        let key = RegistrationKey(factory: factory, name: name)
        
        // Create a registration instance that encapsulates the provided factory.
        let registration = Registration(
            container: self,
            key: key,
            factory: factory,
            instanceType: Graph.self
        )
        
        // Before adding the new registration, ensure that it is allowed based on existing registrations.
        // Perform the actual registration by adding the key-registration pair to the dictionary
        // within a synchronized block to ensure thread safety.
        let source = RegistrationSource.current
        serialQueue.sync {
            registrations[key] = registration
            recorder.record(key, source: source)
            // Notify all registered behaviors that a new registration has been added. This allows behaviors
            // to react to registration events, such as logging or performing additional setup.
            behaviors.forEach {
                $0.didRegister(type: productType, to: self, as: registration, with: name)
            }
        }
        // Return the newly created registration.
        return registration
    }
    
    @discardableResult
    public func register<Product, Argument: Hashable>(
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        factory: Factory<Product, (Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        // Create a unique key for the registration.
        let key = RegistrationKey(factory: factory, name: name)
        
        // Create a registration instance that holds the factory and the argument type.
        let registration = ArgumentRegistration(
            container: self,
            key: key,
            factory: factory,
            instanceType: Graph.self
        )
        
        // Ensure that this registration is allowed based on any existing registrations.
        // Add the registration to the dictionary in a thread-safe manner.
        let source = RegistrationSource.current
        serialQueue.sync {
            registrations[key] = registration
            recorder.record(key, source: source)
            // Notify all registered behaviors about the new registration.
            behaviors.forEach {
                $0.didRegister(type: productType, to: self, as: registration, with: name)
            }
        }
        // Return the created registration.
        return registration
    }
    
    public func isRegistered<Product>(productType: Product.Type, with name: String?) -> Bool {
        // Create a key representing the registration to check.
        // We need to try both AsyncBlock and SyncBlock factory types because the key needs to match
        // the factory type used during registration.
        let asyncKey = RegistrationKey(
            factoryType: Factory<Product, Resolver>.AsyncBlock.self,
            productType: Product.self,
            name: name
        )
        let syncKey = RegistrationKey(
            factoryType: Factory<Product, Resolver>.SyncBlock.self,
            productType: Product.self,
            name: name
        )
        
        // Check if either of these keys exists in the registrations dictionary.
        return serialQueue.sync {
            registrations.keys.contains(asyncKey) || registrations.keys.contains(syncKey)
        }
    }
    
    public func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool {
        // Create keys for both async and sync argumented factories.
        let asyncKey = RegistrationKey(
            factoryType: Factory<Product, (Resolver, Argument)>.AsyncBlock.self,
            productType: Product.self,
            argumentType: Argument.self,
            name: name
        )
        let syncKey = RegistrationKey(
            factoryType: Factory<Product, (Resolver, Argument)>.SyncBlock.self,
            productType: Product.self,
            argumentType: Argument.self,
            name: name
        )
        
        // Check if either of these keys exists.
        return serialQueue.sync {
            registrations.keys.contains(asyncKey) || registrations.keys.contains(syncKey)
        }
    }
    
    public func clear() {
        // Remove all key-value pairs from the registrations dictionary in a thread-safe way.
        serialQueue.sync {
            registrations.removeAll()
            behaviors.removeAll()
            recorder.reset()
        }
    }
    
    public func registrationReport() -> RegistrationReport {
        recorder.report()
    }
    
    public func add(_ behavior: Behavior) {
        // Append the provided behavior to the list of registered behaviors.
        serialQueue.sync {
            behaviors.append(behavior)
        }
    }
    
    public func forward<Conformance, Product>(
        _ type: Conformance.Type,
        to registration: any Registrable<Product>
    ) {
        let name = registration.key.name
        
        let key = RegistrationKey(
            factoryType: Factory<Conformance, Resolver>.AsyncBlock.self,
            productType: Conformance.self,
            argumentType: registration.argumentType,
            name: name
        )
        
        let source = RegistrationSource(
            assembly: RegistrationSource.currentAssembly,
            forwardedFrom: String(describing: Product.self)
        )
        serialQueue.sync {
            registrations[key] = registration
            recorder.record(key, source: source)
            behaviors.forEach {
                $0.didRegister(type: type, to: self, as: registration, with: name)
            }
        }
    }
}

// MARK: Conform to Resolver
extension AsyncContainer: Resolver {
    public func resolve<Product>(
        productType type: Product.Type,
        name: String?
    ) async throws -> Product {
        try await manageContext(ResolutionContext.currentContext) {
            try await initiateResolution(type, name: name, argument: Empty?(nil))
        }
    }
    
    public func resolve<Product, Argument: Hashable>(
        productType type: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        try await manageContext(ResolutionContext.currentContext) {
            try await initiateResolution(type, name: name, argument: argument)
        }
    }
    
    /// This method is intentionally not supported in `AsyncContainer` to enforce asynchronous resolution.
    /// Attempting to call this will result in a fatal error.
    public func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) throws -> Product {
        fatalError("Synchronous resolution is not supported by AsyncContainer. Use async resolve methods instead.")
    }
    
    /// This method is intentionally not supported in `AsyncContainer` to enforce asynchronous resolution.
    /// Attempting to call this will result in a fatal error.
    public func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        fatalError("Synchronous resolution is not supported by AsyncContainer. Use async resolve methods instead.")
    }
}

// MARK: Helper Functions
extension AsyncContainer {
    /// Initiates the resolution process for a product, handling key creation,
    /// circular dependency checks, and context management before delegating
    /// to the actual registration lookup and resolution.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to resolve.
    ///   - name: An optional name for the registration.
    ///   - argument: An optional argument value required by the product's factory.
    ///   - factoryType: The *type* of the factory block (e.g., `Factory<P, R>.AsyncBlock.self`).
    /// - Returns: An instance of the resolved `Product`.
    /// - Throws: `AstrojectError.cyclicDependency` if a circular dependency is found,
    ///           or `AstrojectError.noRegistrationFound` if no suitable registration exists,
    ///           or any error thrown by the product's factory.
    func initiateResolution<Product, Argument: Hashable>(
        _ productType: Product.Type,
        name: String?,
        argument: Argument?
    ) async throws -> Product {
        try isAssembled()
        
        let key: RegistrationKey
        
        if argument != nil {
            key = RegistrationKey(
                factoryType: Factory<Product, (Resolver, Argument)>.AsyncBlock.self,
                productType: productType,
                argumentType: Argument.self,
                name: name
            )
        } else {
            key = RegistrationKey(
                factoryType: Factory<Product, Resolver>.AsyncBlock.self,
                productType: productType,
                name: name
            )
        }
        
        let context = ResolutionContext.currentContext
        let graph = context.graph
        
        // Check for circular dependency
        if graph.contains(key) {
            throw AstrojectError.cyclicDependency(key: graph.first ?? key, path: graph)
        }
        
        // Push onto the task-local resolution path
        return try await ResolutionContext.current.withValue(context.push(key)) {
            let resolvedProduct: Product = try await findAndResolve(for: key, with: argument)
            // Notify behaviors after successful resolution
            serialQueue.sync {
                if let registration = registrations[key] as? (any Registrable<Product>) {
                    behaviors.forEach { $0.didResolve(type: productType, to: self, as: registration, with: name) }
                }
            }
            return resolvedProduct
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
    ) async throws -> Product {
        let product: Product
        
        // Retrieve registration based on the key
        let registration = serialQueue.sync {
            registrations[key]
        }
        
        guard let registration else {
            throw AstrojectError.noRegistrationFound(key: key)
        }
        
        if let argumentValue = argument {
            guard let temp = try await registration.resolve(self, argument: argumentValue) as? Product else {
                throw AstrojectError.noRegistrationFound(key: key)
            }
            
            product = temp
        } else {
            // attempt to resolve the registration
            guard let temp = try await registration.resolve(self) as? Product else {
                throw AstrojectError.noRegistrationFound(key: key)
            }
            
            product = temp
        }
        
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
        
        return product
    }
    
    /// A generic helper function to manage the `Context` for resolution calls.
    /// It handles creating a fresh context for top-level resolutions or
    /// advancing the context for nested resolutions.
    ///
    /// - Parameter body: A throwing closure that performs the actual resolution logic.
    /// - Returns: The resolved product instance.
    /// - Throws: Any error thrown by the `body` closure.
    func manageContext<T, C: Context>(
        _ currentContext: C,
        body: () async throws -> T
    ) async throws -> T {
        if currentContext.depth == 0 {
            // Top-level resolution: create fresh context with new graph ID and empty path
            return try await C.current.withValue(C.fresh()) {
                try await body()
            }
        } else {
            // Nested resolution: increment depth but keep same graphID and continue path
            let nextContext = currentContext.next()
            return try await C.current.withValue(nextContext) {
                try await body()
            }
        }
    }
    
}
