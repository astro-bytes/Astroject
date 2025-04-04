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
    // TODO: Comment
    let argumentType: Any.Type?
    
    /// Initializes a new `RegistrationKey` instance.
    ///
    /// - parameter productType: The type of the product being registered.
    /// - parameter name: An optional name associated with the registration (default is `nil`).
    /// - parameter argumentType: TODO
    init<Product, Argument>(productType: Product.Type, name: String? = nil, argumentType: Argument.Type? = nil) {
        self.productType = productType
        self.name = name
        self.argumentType = argumentType
    }
}

extension RegistrationKey {
    // TODO: Comment
    init<Product>(productType: Product.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
        self.argumentType = nil
    }
}

extension RegistrationKey: Hashable {
    /// Hashes the components of the `RegistrationKey` into the given hasher.
    ///
    /// This function combines the hash values of the product type and the optional
    /// name to generate a unique hash value for the `RegistrationKey`.
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
    /// This function compares the product type and the optional name of two
    /// `RegistrationKey` instances to determine if they are equal.
    ///
    /// - parameter lhs: The left-hand side key.
    /// - parameter rhs: The right-hand side key.
    /// - Returns: `true` if the keys are equal, `false` otherwise.
    static func == (lhs: RegistrationKey, rhs: RegistrationKey) -> Bool {
        return lhs.productType == rhs.productType && lhs.name == rhs.name
    }
}
