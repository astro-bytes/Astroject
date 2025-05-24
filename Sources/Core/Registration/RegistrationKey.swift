//
// RegistrationKey.swift
// Astroject
//
// Created by Porter McGary on 2/25/25.
//

import Foundation

/// A key used to identify registrations in the `Container`.
///
/// The `RegistrationKey` struct is used to uniquely identify registrations within the dependency injection `Container`.
/// It encapsulates the product type and an optional name, allowing for both named and unnamed registrations.
public struct RegistrationKey: Sendable {
    /// The type of the factory block associated with this registration.
    /// This helps differentiate registrations that might produce the same `productType`
    /// but use different factory implementations (e.g., synchronous vs. asynchronous, or factories
    /// with different argument signatures when the argument type is `Void`).
    public let factoryType: Any.Type
    /// The type of the product being registered.
    public let productType: Any.Type
    /// An optional type of the argument used for registrations that require arguments.
    /// This is used to differentiate between registrations of the same product type
    /// with different argument types. If a registration does not take an argument, this will be `nil`.
    public let argumentType: Any.Type?
    /// An optional name associated with the registration.
    public let name: String?

    /// Initializes a `RegistrationKey` for a registration that takes an argument.
    ///
    /// - Parameters:
    ///   - factoryType: The type of the factory block (e.g., `Factory<Product, (Resolver, Argument)>.SyncBlock.self`).
    ///   - productType: The type of the product being registered.
    ///   - argumentType: The type of the argument required by the product's factory.
    ///   - name: An optional name for the registration.
    public init<Factory, Product, Argument>(
        factoryType: Factory.Type,
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String? = nil
    ) {
        self.factoryType = factoryType
        self.productType = productType
        self.argumentType = argumentType
        self.name = name
    }

    /// Initializes a `RegistrationKey` for a registration that does not take an argument.
    ///
    /// - Parameters:
    ///   - factoryType: The type of the factory block (e.g., `Factory<Product, Resolver>.SyncBlock.self`).
    ///   - productType: The type of the product being registered.
    ///   - name: An optional name for the registration.
    public init<Factory, Product>(
        factoryType: Factory.Type,
        productType: Product.Type,
        name: String? = nil
    ) {
        self.factoryType = factoryType
        self.productType = productType
        self.argumentType = nil
        self.name = name
    }

    /// Initializes a `RegistrationKey` from a `Factory` for a product that does not require an argument.
    ///
    /// This convenience initializer infers the `productType` and `factoryType` directly from the provided `Factory`.
    ///
    /// - Parameters:
    ///   - factory: The `Factory` instance used for the registration.
    ///   - name: An optional name for the registration.
    public init<Product>(
        factory: Factory<Product, Resolver>,
        name: String? = nil
    ) {
        switch factory.block {
        case .sync(let block):
            self.init(
                factoryType: type(of: block),
                productType: Product.self,
                name: name
            )
        case .async(let block):
            self.init(
                factoryType: type(of: block),
                productType: Product.self,
                name: name
            )
        }

    }

    /// Initializes a `RegistrationKey` from a `Factory` for a product that requires an argument.
    ///
    /// This convenience initializer infers the `productType`, `argumentType`, and `factoryType`
    /// directly from the provided `Factory`.
    ///
    /// - Parameters:
    ///   - factory: The `Factory` instance used for the registration.
    ///   - name: An optional name for the registration.
    public init<Product, Argument>(
        factory: Factory<Product, (Resolver, Argument)>,
        name: String? = nil
    ) {
        switch factory.block {
        case .sync(let block):
            self.init(
                factoryType: type(of: block),
                productType: Product.self,
                argumentType: Argument.self,
                name: name
            )
        case .async(let block):
            self.init(
                factoryType: type(of: block),
                productType: Product.self,
                argumentType: Argument.self,
                name: name
            )
        }
    }
}

extension RegistrationKey: Hashable {
    /// Hashes the components of the `RegistrationKey` into the given hasher.
    ///
    /// This function combines the hash values of the product type, the optional
    /// name, and the optional argument type to generate a unique hash value for the
    /// `RegistrationKey`. The `ObjectIdentifier` is used to get a unique representation
    /// of the type.
    ///
    /// - parameter hasher: The hasher to use for combining the components.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.factoryType))
        hasher.combine(ObjectIdentifier(self.productType))

        if let argumentType {
            hasher.combine(ObjectIdentifier(argumentType))
        }

        if let name {
            hasher.combine(name)
        }
    }
}

extension RegistrationKey: Equatable {
    /// Checks if two `RegistrationKey` instances are equal.
    ///
    /// This function compares the factory type, the product type, the optional name,
    /// and the optional argument type of two `RegistrationKey` instances to determine if they are equal.
    ///
    /// - parameter lhs: The left-hand side key.
    /// - parameter rhs: The right-hand side key.
    /// - Returns: `true` if the keys are equal, `false` otherwise.
    public static func == (lhs: RegistrationKey, rhs: RegistrationKey) -> Bool {
        lhs.factoryType == rhs.factoryType &&
        lhs.productType == rhs.productType &&
        lhs.argumentType == rhs.argumentType &&
        lhs.name == rhs.name
    }
}
