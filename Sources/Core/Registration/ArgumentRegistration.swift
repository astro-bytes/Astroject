//
//  ArgumentRegistration.swift
//  Astroject
//
//  Created by Porter McGary on 5/18/25.
//

import Foundation

/// Represents a registration that requires an argument to resolve the product.
///
/// This class extends `Registrable` to handle dependencies that need an argument during resolution.
/// It stores the factory, instance management strategy, and post-initialization actions.
public final class ArgumentRegistration<Product, Argument: Hashable>: Registrable {
    public typealias Action = (Resolver, Product) throws -> Void
    public typealias Arguments = (Resolver, Argument)
    
    /// The factory used to create instances of the product with an argument.
    let factory: Factory<Product, Arguments>
    
    /// The container in which this registration is stored.
    ///
    /// It is used primarily to enable operations such as type forwarding (`implements`)
    /// so that the registration can participate in broader container-level resolution behaviors.
    /// Although not directly involved in instance creation, it is essential for supporting
    /// registration metadata and container coordination.
    let container: any Container
    
    /// An array of actions to be performed after a product is resolved.
    private(set) var actions: [Action] = []
    
    /// The instance storage keyed by argument, each managing contextual product instances.
    private(set) var instances: [Argument: any Instance<Product>] = [:]
    
    /// The type of instance manager (e.g., `Singleton.self`, `Transient.self`) that will be used for products
    /// resolved by this registration, if an argument-specific instance is not already set.
    private(set) var instanceType: any Instance<Product>.Type
    
    public let isOverridable: Bool
    public let argumentType: Any.Type
    public let key: RegistrationKey
    
    /// Initializes a new `ArgumentRegistration` instance with the necessary components.
    ///
    /// - Parameters:
    ///   - factory: The `Factory` responsible for creating product instances.
    ///   - isOverridable: A boolean indicating whether this registration can be overridden by subsequent registrations.
    ///   - instanceType: The default instance management strategy to use for products resolved by this registration.
    public init(
        container: any Container,
        key: RegistrationKey,
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        instanceType: any Instance<Product>.Type
    ) {
        self.container = container
        self.key = key
        self.factory = factory
        self.isOverridable = isOverridable
        self.argumentType = Argument.self
        self.instanceType = instanceType
    }
    
    /// Internal initializer for testability that allows setting a custom instance for a specific argument.
    ///
    /// This initializer is used primarily in unit tests to inject a preconfigured instance manager for a
    /// given argument.
    ///
    /// - Parameters:
    ///   - factory: The factory used to produce product instances.
    ///   - isOverridable: Indicates whether the registration is overridable.
    ///   - argument: The specific argument key for which to store the provided instance.
    ///   - instance: A pre-initialized instance manager to associate with the argument.
    init(
        container: any Container,
        key: RegistrationKey,
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        argument: Argument,
        instance: any Instance<Product>
    ) {
        self.container = container
        self.key = key
        self.factory = factory
        self.isOverridable = isOverridable
        self.argumentType = type(of: argument)
        self.instanceType = type(of: instance)
        self.instances[argument] = instance
    }
    
    public func resolve<A>(
        container: Container,
        argument: A,
        in context: any Context
    ) async throws -> Product {
        guard let argument = argument as? Argument else {
            throw AstrojectError.invalidArgument
        }
        
        guard let product = instances[argument]?.get(for: context) else {
            do {
                let product: Product = try await factory((container, argument))
                try set(product, with: argument, in: context, in: container)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        return product
    }
    
    public func resolve<A>(
        container: Container,
        argument: A,
        in context: any Context
    ) throws -> Product {
        guard let argument = argument as? Argument else {
            throw AstrojectError.invalidArgument
        }
        
        guard let product = instances[argument]?.get(for: context) else {
            do {
                let product: Product = try factory((container, argument))
                try set(product, with: argument, in: context, in: container)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        return product
    }
    
    @discardableResult
    public func `as`(_ instance: any Instance<Product>.Type) -> Self {
        guard instance != instanceType else { return self }
        instanceType = instance
        instances = [:] // Reset instances if the instance type changes
        return self
    }
    
    @discardableResult
    public func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
    
    public func key(with name: String? = nil) -> RegistrationKey {
        .init(factory: factory, name: name)
    }
    
    public func implements<T>(_ type: T.Type) -> Self {
        container.forward(type, to: self)
        return self
    }
}

extension ArgumentRegistration {
    /// Sets a product instance for a specific argument and context, managed by the determined instance strategy.
    ///
    /// - Parameters:
    ///   - product: The product instance to store.
    ///   - argument: The argument key under which to store the product instance.
    ///   - context: The context relevant for instance management.
    ///   - container: The container used for executing post-initialization actions.
    func set(
        _ product: Product,
        with argument: Argument,
        in context: any Context,
        in container: Container
    ) throws {
        let instance = instanceType.init()
        instance.set(product, for: context)
        self.instances[argument] = instance
        try runActions(for: product, in: container)
    }
    
    /// Runs the post-initialization actions.
    ///
    /// This function executes the post-initialization actions associated with the registration. These actions
    /// are performed after the instance is created but before it is returned to the resolver.
    ///
    /// - parameter product: The resolved product instance.
    /// - parameter container: The container used for dependency resolution.
    /// - Throws: `AstrojectError.afterInit` if an error occurs during action execution.
    func runActions(for product: Product, in container: Container) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.afterInit(error)
        }
    }
}

extension ArgumentRegistration: Equatable where Product: Equatable {
    /// Checks if two registrations are equal by comparing instance values in the given context.
    ///
    /// This comparison includes checking instance equality for each argument key.
    ///
    /// - Parameters:
    ///   - other: Another registration to compare with.
    ///   - context: The resolution context to retrieve instance values.
    /// - Returns: `true` if all instances and metadata match; otherwise `false`.
    public func isEqual(
        to other: ArgumentRegistration<Product, Argument>,
        in context: any Context = ResolutionContext.currentContext
    ) -> Bool {
        guard instances.allSatisfy({ (argument, instance) -> Bool in
            guard let otherInstance = other.instances[argument] else { return false }
            return instance.get(for: context) == otherInstance.get(for: context)
        }) else { return false }
        
        return self == other
    }
    
    /// Checks if two registrations are equal.
    ///
    /// This function compares the instance management strategy, overridable status,
    /// factory, and argument type of two `ArgumentRegistration` instances to
    /// determine if they are equal.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    public static func == (
        lhs: ArgumentRegistration<Product, Argument>,
        rhs: ArgumentRegistration<Product, Argument>
    ) -> Bool {
        lhs.instances.keys == rhs.instances.keys &&
        lhs.instanceType == rhs.instanceType &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory &&
        lhs.argumentType == rhs.argumentType
    }
}
