//
//  RegistrationWithArgument.swift
//  Astroject
//
//  Created by Porter McGary on 5/18/25.
//

import Foundation

/// Represents a registration that requires an argument to resolve the product.
///
/// This class extends `Registrable` to handle dependencies that need an argument during resolution.
/// It stores the factory, instance management strategy, and post-initialization actions.
public final class RegistrationWithArgument<Product, Argument: Hashable>: Registrable {
    /// A closure type for actions to be performed after a product is resolved.
    /// This closure takes a resolver and the resolved product as input.
    public typealias Action = (Resolver, Product) throws -> Void
    /// A tuple type representing the arguments required by the factory.
    /// It includes the resolver and the argument.
    public typealias Arguments = (Resolver, Argument)
    
    /// The factory used to create instances of the product with an argument.
    let factory: Factory<Product, Arguments>
    /// The type of the argument required for this registration.
    let argumentType: Argument.Type
    
    /// An array of actions to be performed after a product is resolved.
    private(set) var actions: [Action] = []
    /// The instance management strategy for the product.
    /// This determines how instances of the product are created and managed.
    private(set) var instances: [Argument: any Instance<Product>] = [:]
    /// The type of instance manager (e.g., `Singleton.self`, `Transient.self`) that will be used for products
    /// resolved by this registration, if an argument-specific instance is not already set.
    private(set) var instanceType: any Instance<Product>.Type
    
    public let isOverridable: Bool
    
    /// Initializes a new `RegistrationWithArgument` instance with the necessary components.
    ///
    /// - Parameters:
    ///   - factory: The `Factory` responsible for creating product instances.
    ///   - isOverridable: A boolean indicating whether this registration can be overridden by subsequent registrations.
    ///   - argumentType: The explicit type of the argument required for this registration.
    ///   - instanceType: The default instance management strategy to use for products resolved by this registration.
    public init(
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instanceType: any Instance<Product>.Type
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.argumentType = argumentType
        self.instanceType = instanceType
    }
    
    /// Initializes a new `RegistrationWithArgument` instance with a factory closure.
    ///
    /// - parameter block: The factory closure used to create instances of the product with an argument.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter argumentType: The type of the argument required for this registration.
    /// - parameter instance: The instance management strategy for the product (default is `Transient`).
    public convenience init(
        factory block: Factory<Product, Arguments>.Block,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instanceType: any Instance<Product>.Type
    ) {
        self.init(
            factory: Factory(block),
            isOverridable: isOverridable,
            argumentType: argumentType,
            instanceType: instanceType
        )
    }
    
    /// Resolves and returns an instance of the product asynchronously, using the provided argument.
    ///
    /// This method first checks if an instance already exists for the given argument and current context.
    /// If not, it uses the registered factory to create a new instance, stores it according
    /// to the instance management strategy (either argument-specific or default), and then runs any
    /// defined `afterInit` actions.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - argument: The argument required by the product's factory.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(_ container: Container, argument: Argument) async throws -> Product {
        let context = Context.current
        guard let product = instances[argument]?.get(for: context) else {
            do {
                let product: Product = try await factory((container, argument))
                set(product, with: argument, in: context)
                try runActions(container, product: product)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        
        return product
    }
    
    /// Resolves and returns an instance of the product synchronously, using the provided argument.
    ///
    /// This method first checks if an instance already exists for the given argument and current context.
    /// If not, it uses the registered factory to create a new instance, stores it according
    /// to the instance management strategy (either argument-specific or default), and then runs any
    /// defined `afterInit` actions.
    ///
    /// - Parameters:
    ///   - container: The `Container` (acting as a `Resolver`) to use for resolving dependencies within the factory.
    ///   - argument: The argument required by the product's factory.
    /// - Returns: An instance of the `Product`.
    /// - Throws: `AstrojectError` if there's a problem during resolution, such as an underlying error from the factory.
    public func resolve(_ container: Container, argument: Argument) throws -> Product {
        let context = Context.current
        guard let product = instances[argument]?.get(for: context) else {
            do {
                let product: Product = try factory((container, argument))
                set(product, with: argument, in: context)
                try runActions(container, product: product)
                return product
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
        
        return product
    }
    
    /// Runs the post-initialization actions.
    ///
    /// This function executes the post-initialization actions associated with the registration. These actions
    /// are performed after the instance is created but before it is returned to the resolver.
    ///
    /// - parameter container: The container used for dependency resolution.
    /// - parameter product: The resolved product instance.
    /// - Throws: `AstrojectError.underlyingError` if an error occurs during action execution.
    public func runActions(_ container: Container, product: Product) throws {
        do {
            // Iterate over each action and execute it.
            try actions.forEach { try $0(container, product) }
        } catch {
            // Wrap any error that occurs during action execution.
            throw AstrojectError.registrationAction(error)
        }
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
}

extension RegistrationWithArgument: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// This function compares the instance management strategy, overridable status,
    /// factory, and argument type of two `RegistrationWithArgument` instances to
    /// determine if they are equal. Note that it compares the result of `instance.get()`,
    /// which may not be the intended behavior for all `Instance` types. For example,
    /// comparing singletons this way is fine, but comparing transients is not.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    public static func == (
        lhs: RegistrationWithArgument<Product, Argument>,
        rhs: RegistrationWithArgument<Product, Argument>
    ) -> Bool {
        let context = Context.current
        
        let instanceTypeCheck = lhs.instanceType == rhs.instanceType
        let argumentInstancesCheck = lhs.instances.allSatisfy { (argument, instance) -> Bool in
            guard let rhsInstance = rhs.instances[argument] else { return false }
            return instance.get(for: context) == rhsInstance.get(for: context)
        }
        
        return instanceTypeCheck &&
        argumentInstancesCheck &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory &&
        lhs.argumentType == rhs.argumentType
    }
}

extension RegistrationWithArgument {
    /// Sets a product instance for a specific argument and context, managed by the determined instance strategy.
    ///
    /// This method initializes an `Instance` of the `instanceType` and uses it to store the provided product.
    /// The instance is then associated with the given argument in the `instances` dictionary.
    ///
    /// - Parameters:
    ///   - product: The product instance to store.
    ///   - argument: The argument key under which to store the product instance.
    ///   - context: The context relevant for instance management.
    func set(_ product: Product, with argument: Argument, in context: Context) {
        let instance = instanceType.init()
        instance.set(product, for: context)
        self.instances[argument] = instance
    }
}
