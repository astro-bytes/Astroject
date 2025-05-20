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
struct RegistrationKey {
    /// The type of the product being registered.
    let productType: Any.Type
    /// An optional name associated with the registration.
    let name: String?
    /// An optional type of the argument used for registrations that require arguments.
    /// This is used to differentiate between registrations of the same product type
    /// with different argument types.  If a registration does not take an argument, this will be `nil`.
    let argumentType: Any.Type?
    
    /// Initializes a new `RegistrationKey` instance.
    ///
    /// - parameter productType: The type of the product being registered.
    /// - parameter name: An optional name associated with the registration (default is `nil`).
    /// - parameter argumentType: The type of the argument associated with the registration.
    ///   This is used to differentiate registrations that require different argument types.
    init<Product, Argument>(productType: Product.Type, name: String? = nil, argumentType: Argument.Type? = nil) {
        self.productType = productType
        self.name = name
        self.argumentType = argumentType
    }
}

extension RegistrationKey {
    /// Initializes a new `RegistrationKey` instance for registrations without arguments.
    ///
    /// This initializer is a convenience initializer to create a `RegistrationKey`
    /// for registrations that do not require an argument.  It internally calls the main initializer
    /// and passes `nil` for the `argumentType`.
    ///
    /// - parameter productType: The type of the product being registered.
    /// - parameter name: An optional name associated with the registration (default is `nil`).
    init<Product>(productType: Product.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
        self.argumentType = nil
    }
}

extension RegistrationKey: Hashable {
    /// Hashes the components of the `RegistrationKey` into the given hasher.
    ///
    /// This function combines the hash values of the product type, the optional
    /// name, and the optional argument type to generate a unique hash value for the
    /// `RegistrationKey`.  The `ObjectIdentifier` is used to get a unique representation
    /// of the type.
    ///
    /// - parameter hasher: The hasher to use for combining the components.
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.productType))
        hasher.combine(self.name)
        if let argumentType {
            hasher.combine(ObjectIdentifier(argumentType))
        }
    }
}

extension RegistrationKey: Equatable {
    /// Checks if two `RegistrationKey` instances are equal.
    ///
    /// This function compares the product type, the optional name, and the optional argument type of two
    /// `RegistrationKey` instances to determine if they are equal.
    ///
    /// - parameter lhs: The left-hand side key.
    /// - parameter rhs: The right-hand side key.
    /// - Returns: `true` if the keys are equal, `false` otherwise.
    static func == (lhs: RegistrationKey, rhs: RegistrationKey) -> Bool {
        return lhs.productType == rhs.productType && lhs.name == rhs.name && lhs.argumentType == rhs.argumentType
    }
}
