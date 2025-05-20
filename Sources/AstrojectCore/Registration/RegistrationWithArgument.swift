//
//  RegistrationWithArgument.swift
//  Astroject
//
//  Created by Porter McGary on 5/18/25.
//

import Foundation

/// Represents a registration that requires an argument to resolve the product.
///
/// This class extends `Registrable` to handle dependencies that need an argument during resolution.
/// It stores the factory, instance management strategy, and post-initialization actions.
class RegistrationWithArgument<Product, Argument: Hashable>: Registrable {
    /// A closure type for actions to be performed after a product is resolved.
    /// This closure takes a resolver and the resolved product as input.
    typealias Action = (Resolver, Product) throws -> Void
    /// A tuple type representing the arguments required by the factory.
    /// It includes the resolver and the argument.
    typealias Arguments = (Resolver, Argument)
    
    /// The factory used to create instances of the product with an argument.
    let factory: Factory<Product, Arguments>
    /// The type of the argument required for this registration.
    let argumentType: Argument.Type
    
    /// An array of actions to be performed after a product is resolved.
    private var actions: [Action] = []
    /// The instance management strategy for the product.
    /// This determines how instances of the product are created and managed.
    private(set) var instances: [Argument: any Instance<Product>] = [:]
    /// The default instance strategy.
    private(set) var defaultInstance: any Instance<Product>
    /// Indicates whether this registration can be overridden by another registration.
    let isOverridable: Bool
    
    /// Initializes a new `RegistrationWithArgument` instance.
    ///
    /// - parameter factory: The factory used to create instances of the product with an argument.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter argumentType: The type of the argument required for this registration.
    /// - parameter instance: The instance management strategy for the product.
    init(
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instance: any Instance<Product>
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.argumentType = argumentType
        self.defaultInstance = instance
    }
    
    /// Initializes a new `RegistrationWithArgument` instance with a factory closure.
    ///
    /// - parameter block: The factory closure used to create instances of the product with an argument.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter argumentType: The type of the argument required for this registration.
    /// - parameter instance: The instance management strategy for the product (default is `Transient`).
    convenience init(
        factory block: @escaping Factory<Product, Arguments>.Block,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instance: any Instance<Product>
    ) {
        self.init(
            factory: Factory(block),
            isOverridable: isOverridable,
            argumentType: argumentType,
            instance: instance
        )
    }
    
    func resolve(_ container: Container, argument: Argument) async throws -> Product {
        let context = Context.current
        
        if let instance = self.instances[argument] {
            if let product = instance.get(for: context) {
                return product
            }
        } else if let product = self.defaultInstance.get(for: context) {
            return product
        }
        
        do {
            // Resolve the product using the factory and the argument.
            let product: Product = try await factory((container, argument))
            // Store the resolved instance according to the instance management strategy.
            let instance = defaultInstance
            instance.set(product, for: context)
            self.instances[argument] = instance
            // Run any post-initialization actions.
            try runActions(container, product: product)
            return product
        } catch let error as AstrojectError {
            // If the error is already an AstrojectError, rethrow it.
            throw error
        } catch {
            // Wrap any other error in an AstrojectError.
            throw AstrojectError.underlyingError(error)
        }
    }
    
    /// Runs the post-initialization actions.
    ///
    /// This function executes the post-initialization actions associated with the registration.  These actions
    /// are performed after the instance is created but before it is returned to the resolver.
    ///
    /// - parameter container: The container used for dependency resolution.
    /// - parameter product: The resolved product instance.
    /// - Throws: `AstrojectError.underlyingError` if an error occurs during action execution.
    private func runActions(_ container: Container, product: Product) throws {
        do {
            // Iterate over each action and execute it.
            try actions.forEach { try $0(container, product) }
        } catch {
            // Wrap any error that occurs during action execution.
            throw AstrojectError.underlyingError(error)
        }
    }
    
    @discardableResult
    func `as`<A: Hashable>(_ instance: any Instance<Product>, with argument: A) throws -> Self {
        guard let argument = argument as? Argument else {
            throw AstrojectError.invalidInstance
        }
        
        self.instances[argument] = instance
        return self
    }
    
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self {
        defaultInstance = instance
        return self
    }
    
    @discardableResult
    func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension RegistrationWithArgument: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// This function compares the instance management strategy, overridable status,
    /// factory, and argument type of two `RegistrationWithArgument` instances to
    /// determine if they are equal.  Note that it compares the result of `instance.get()`,
    /// which may not be the intended behavior for all `Instance` types.  For example,
    /// comparing singletons this way is fine, but comparing transients is not.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    static func == (
        lhs: RegistrationWithArgument<Product, Argument>,
        rhs: RegistrationWithArgument<Product, Argument>
    ) -> Bool {
        let context = Context.current
        
        // check default instance and argument instances
        let defaultInstanceCheck = lhs.defaultInstance.get(for: context) == rhs.defaultInstance.get(for: context)
        let argumentInstancesCheck = lhs.instances.allSatisfy { (argument, instance) -> Bool in
            guard let rhsInstance = rhs.instances[argument] else { return false }
            return instance.get(for: context) == rhsInstance.get(for: context)
        }
        
        return defaultInstanceCheck && argumentInstancesCheck &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory &&
        lhs.argumentType == rhs.argumentType
    }
}
