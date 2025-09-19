//
// Registrable.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a registrable component that can be resolved by a `Container`.
///
/// The `Registrable` protocol is used to define components that can be
/// registered with a dependency injection `Container`.
/// It provides methods for configuring the instance management scope and post
/// -initialization actions for the registered component.
public protocol Registrable<Product> {
    /// A closure type for actions to be performed after a product is resolved.
    associatedtype Action
    
    /// The type of product that this registrable component produces.
    associatedtype Product
    
    /// A boolean value indicating whether this registration can be overridden by another registration for
    /// the same product type.
    var isOverridable: Bool { get }
    
    /// The type of argument required to resolve this registration.
    ///
    /// This property is used for introspection and type comparison within the container.
    /// It allows the resolution logic to validate that the argument provided matches the expected type
    /// at runtime. It is particularly useful for distinguishing between different `ArgumentRegistration`
    /// types registered under the same product type.
    var argumentType: Any.Type { get }
    
    /// A unique key representing the registration.
    ///
    /// The key encodes identifying information for the registration, such as the factory reference
    /// and any associated name. It is used internally by the container to match and retrieve the
    /// appropriate registration during resolution.
    var key: RegistrationKey { get }
    
    /// Specifies the instance management strategy for the registered product.
    ///
    /// This function allows you to define how instances of the `Product` will be
    /// created and managed by the dependency injection container.
    ///
    /// - Parameter instance: The type of `Instance` (e.g., `Singleton.self`, `Transient.self`)
    ///   that will manage the product's lifecycle.
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func `as`(_ instance: any Instance<Product>.Type) -> Self
    
    /// Sets an action to be performed after the product is initialized.
    ///
    /// This function allows configuring a post-initialization action that will be
    /// executed after the product instance is created.
    ///
    /// - parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func afterInit(perform action: Action) -> Self
    
    /// Resolves and returns an instance of the product synchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    func resolve<Argument>(
        container: Container,
        argument: Argument,
        in context: any Context
    ) throws -> Product
    
    /// Resolves and returns an instance of the product asynchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    func resolve<Argument>(
        container: Container,
        argument: Argument,
        in context: any Context
    ) async throws -> Product
    
    /// Forwards the current registration to an additional type.
    ///
    /// This enables multiple types to resolve to the same underlying product instance.
    /// For example, you can register a concrete type and then call `.implements(MyProtocol.self)`
    /// to allow resolution by the protocol as well.
    ///
    /// - Parameter type: The additional type to forward the registration to.
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func implements<T>(_: T.Type) -> Self
}

// MARK: Convenience Functions
public extension Registrable {
    /// Resolves and returns an instance of the product synchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    func resolve<Argument>(
        _ container: Container,
        argument: Argument = Empty(),
        in context: any Context = ResolutionContext.currentContext
    ) throws -> Product {
        try self.resolve(container: container, argument: argument, in: context)
    }
    
    /// Resolves and returns an instance of the product asynchronously.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - context: The resolution context, used to isolate instances across scopes.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    func resolve<Argument>(
        _ container: Container,
        argument: Argument = Empty(),
        in context: any Context = ResolutionContext.currentContext
    ) async throws -> Product {
        try await self.resolve(container: container, argument: argument, in: context)
    }
}

// MARK: Instance's
public extension Registrable {
    /// Specifies that the registered product should be a **singleton**.
    ///
    /// A singleton instance means that only one instance of the product will be
    /// created and reused throughout the application's lifecycle.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asSingleton() -> Self {
        return self.as(Singleton.self)
    }
    
    /// Specifies that the registered product should be a **disposable singleton**.
    ///
    /// A disposable singleton instance means that only one instance of the product will be
    /// created and reused throughout the application's lifecycle, until disposed and another is created.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asDisposableSingleton() -> Self {
        return self.as(DisposableSingleton.self)
    }
    
    /// Specifies that a **new instance** of the product should be created **each time** it is resolved.
    ///
    /// This is often referred to as a "transient" or "factory" scope.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asTransient() -> Self {
        return self.as(Transient.self)
    }
    
    /// Specifies that the registered product should be scoped to its **dependency graph**.
    ///
    /// This means that a new instance will be created for each distinct resolution
    /// operation that involves this product, but if the product is a dependency
    /// within a larger graph, the same instance will be reused within that graph.
    ///
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asGraph() -> Self {
        return self.as(Graph.self)
    }
}

public extension Registrable where Product: AnyObject {
    /// Specifies that the registered product should be a **weak** instance.
    ///
    /// A weak instance means that the container will hold a weak reference to the
    /// product. If no other strong references exist, the instance can be deallocated.
    /// - Warning: The `Product` **MUST** be a class type.
    ///            If using a Protocol you must register initially with the concrete type
    ///            then use the `forward` method on the container to forward the
    ///            registration to the protocol type.
    /// - Returns: The modified `Registrable` instance for chaining.
    @discardableResult
    func asWeak() -> Self {
        return self.as(Weak.self)
    }
}
