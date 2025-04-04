//
//  RegistrationWithArgument.swift
//  Astroject
//
//  Created by Porter McGary on 5/18/25.
//

import Foundation

// TODO: Comment
class RegistrationWithArgument<Product, Argument: Hashable>: Registrable {
    /// A closure type for actions to be performed after a product is resolved.
    typealias Action = (Resolver, Product) throws -> Void
    // TODO: Comment
    typealias Arguments = (Resolver, Argument)
    
    /// The factory used to create instances of the product.
    let factory: Factory<Product, Arguments>
    // TODO: Comment
    let argumentType: Argument.Type
    
    /// An array of actions to be performed after a product is resolved.
    private var actions: [Action] = []
    
    /// The instance management strategy for the product.
    private(set) var instance: any Instance<Product>
    
    /// Indicates whether this registration can be overridden by another registration.
    let isOverridable: Bool
    
    /// Initializes a new `Registration` instance.
    ///
    /// - parameter factory: The factory used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product (default is `Prototype`).
    init(
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instance: any Instance<Product> = Prototype<Product>()
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
        self.argumentType = argumentType
    }
    
    /// Initializes a new `Registration` instance with a factory closure.
    ///
    /// - parameter block: The factory closure used to create instances of the product.
    /// - parameter isOverridable: Indicates whether this registration can be overridden.
    /// - parameter instance: The instance management strategy for the product (default is `Prototype`).
    convenience init(
        factory block: @escaping Factory<Product, Arguments>.Block,
        isOverridable: Bool,
        argumentType: Argument.Type,
        instance: any Instance<Product> = Prototype<Product>()
    ) {
        self.init(
            factory: Factory(block),
            isOverridable: isOverridable,
            argumentType: argumentType,
            instance: instance
        )
    }
    
    /// Resolves the product instance asynchronously.
    ///
    /// This function retrieves the product instance based on the instance management strategy.
    /// If the instance is not yet created, it uses the factory to create it and runs any post-initialization actions.
    ///
    /// - parameter container: The container used for dependency resolution.
    /// - Returns: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during creation or post-initialization.
    func resolve(_ container: Container, argument: Argument) async throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            do {
                let product: Product = try await factory((container, argument))
//                self.instance.set(product, argument: argument)
//                try runActions(container, product: product)
//                return product
                fatalError("Needs Implemented")
            } catch let error as AstrojectError {
                throw error
            } catch {
                throw AstrojectError.underlyingError(error)
            }
        }
    }
    
    /// Runs the post-initialization actions.
    ///
    /// This function executes the post-initialization actions associated with the registration.
    ///
    /// - parameter container: The container used for dependency resolution.
    /// - parameter product: The resolved product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during action execution.
    private func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw AstrojectError.underlyingError(error)
        }
    }
    
    /// Sets the instance management scope for the registration.
    ///
    /// This function allows configuring how the registered component's instances
    /// are managed, such as singleton, prototype, or weak references.
    ///
    /// - parameter instance: The instance management strategy.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func `as`(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    /// Adds a post-initialization action to the registration.
    ///
    /// This function allows configuring a post-initialization action that will be executed
    /// after the product instance is created.
    ///
    /// - parameter action: The action to be performed.
    /// - Returns: The modified `Registration` instance.
    @discardableResult
    func afterInit(perform action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension RegistrationWithArgument: Equatable where Product: Equatable {
    /// Checks if two registrations are equal.
    ///
    /// - parameter lhs: The left-hand side registration.
    /// - parameter rhs: The right-hand side registration.
    /// - Returns: `true` if the registrations are equal, `false` otherwise.
    static func == (lhs: RegistrationWithArgument<Product, Argument>, rhs: RegistrationWithArgument<Product, Argument>) -> Bool {
        return lhs.instance.get() == rhs.instance.get() &&
        lhs.isOverridable == rhs.isOverridable &&
        lhs.factory == rhs.factory &&
        lhs.argumentType == rhs.argumentType
    }
}
