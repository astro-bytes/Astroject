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
public protocol Container: AnyObject, Resolver, Sendable {
    /// Registers a factory for a product that does not require an argument for resolution.
    ///
    /// Use this method to bind a `productType` to a `factory` closure. When the product
    /// is later resolved, the provided `factory` will be executed to create its instance.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name to differentiate multiple registrations of the same `productType`.
    ///   - factory: A `Factory` closure that takes a `Resolver` and returns an instance of `Product`.
    /// - Returns: The `Registrable` instance representing this registration, allowing for further configuration.
    @discardableResult
    func register<Product>(
        productType: Product.Type,
        name: String?,
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
    ///   - factory: A `Factory` closure that takes a `Resolver` and an `Argument`,
    ///              then returns an instance of `Product`.
    /// - Returns: The `Registrable` instance representing this registration, allowing for further configuration.
    @discardableResult
    func register<Product, Argument: Hashable>(
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String?,
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
    
    /// Forwards a registration to an additional conformance type.
    ///
    /// This enables the same registered instance to be resolved via multiple types,
    /// typically a concrete implementation and one or more protocol abstractions.
    /// For example, after registering a concrete type, you can forward that registration
    /// to a protocol it conforms to, allowing resolution by the protocol type.
    ///
    /// - Parameters:
    ///   - conformance: The protocol or superclass type to which the registration should be forwarded.
    ///   - registration: The existing registration to forward from.
    func forward<Conformance, Product>(
        _: Conformance.Type,
        to registration: any Registrable<Product>
    )
    
    /// A report of every registration this container has received, grouped by key.
    ///
    /// Registration is last one wins. The report lists, for each key, every registration made
    /// for it in order and where each came from, so you can see which registration the
    /// container resolves and which ones it replaced.
    ///
    /// Defaults to an empty report for containers that don't record registrations.
    func registrationReport() -> RegistrationReport
    
    /// How this container resolves dependencies from inside its factories.
    ///
    /// Synchronous containers call factories synchronously, so a factory must resolve its own
    /// dependencies with the synchronous `resolve`. Asynchronous containers require the `async`
    /// `resolve`. Extensions that build factories for you, such as Nexus's `register(_:initializer:)`,
    /// use this to pick the right kind of factory.
    ///
    /// Defaults to `.sync`.
    var resolutionMode: ResolutionMode { get }
}

/// How a `Container` resolves dependencies from inside its factories.
public enum ResolutionMode: Sendable, Equatable {
    /// Factories resolve dependencies with the synchronous `resolve` methods.
    case sync
    /// Factories resolve dependencies with the `async` `resolve` methods.
    case async
}

/// ### Default Implementations for `Container`
///
/// These extensions provide convenience methods for registering and checking dependencies,
/// allowing for more concise code when the `name` parameter can use its default.
public extension Container {
    /// The default resolution mode, `.sync`.
    var resolutionMode: ResolutionMode { .sync }
    
    /// The default registration report, which is empty.
    func registrationReport() -> RegistrationReport { RegistrationReport() }
    
    /// Writes the registration report to the console through `os.Logger`, with the subsystem `Astroject`.
    ///
    /// An `Assembler` does this for you after `assemble()` in debug builds. Call it yourself
    /// when you register without an assembler.
    ///
    /// - Parameter onlyOverridden: When `true`, lists only keys that were registered more
    ///   than once. Defaults to `true`.
    func printRegistrationReport(onlyOverridden: Bool = true) {
        registrationReport().log(onlyOverridden: onlyOverridden)
    }
    
    /// Registers a factory for a product that does not require an argument,
    /// with `name` defaulting to `nil`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - name: An optional name. Defaults to `nil`.
    ///   - factory: The factory closure.
    ///   - fileID: The file the registration is made from, for the registration report. Defaults to `#fileID`.
    ///   - line: The line the registration is made from, for the registration report. Defaults to `#line`.
    /// - Returns: The `Registrable` instance.
    @discardableResult
    func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        factory: Factory<Product, Resolver>,
        fileID: String = #fileID,
        line: UInt = #line
    ) throws -> any Registrable<Product> {
        try RegistrationSource.withCallSite(fileID: fileID, line: line) { () throws -> any Registrable<Product> in
            try self.register(
                productType: productType,
                name: name,
                factory: factory
            )
        }
    }
    
    /// Registers a factory for a product that requires an argument,
    /// with `name` defaulting to `nil`.
    ///
    /// - Parameters:
    ///   - productType: The type of the product to register.
    ///   - argumentType: The type of the argument required.
    ///   - name: An optional name. Defaults to `nil`.
    ///   - factory: The factory closure.
    ///   - fileID: The file the registration is made from, for the registration report. Defaults to `#fileID`.
    ///   - line: The line the registration is made from, for the registration report. Defaults to `#line`.
    /// - Returns: The `Registrable` instance.
    @discardableResult
    func register<Product, Argument: Hashable>(
        _ productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil,
        factory: Factory<Product, (Resolver, Argument)>,
        fileID: String = #fileID,
        line: UInt = #line
    ) throws -> any Registrable<Product> {
        try RegistrationSource.withCallSite(fileID: fileID, line: line) { () throws -> any Registrable<Product> in
            try self.register(
                productType: productType,
                argumentType: argumentType,
                name: name,
                factory: factory
            )
        }
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
