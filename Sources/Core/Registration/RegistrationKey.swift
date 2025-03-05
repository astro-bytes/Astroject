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
    
    /// Initializes a new `RegistrationKey` instance.
    ///
    /// - Parameters:
    ///     - productType: The type of the product being registered.
    ///     - name: An optional name associated with the registration (default is `nil`).
    init<Product>(productType: Product.Type, name: String? = nil) {
        self.productType = productType
        self.name = name
    }
}

extension RegistrationKey: Hashable {
    /// Hashes the components of the `RegistrationKey` into the given hasher.
    ///
    /// This function combines the hash values of the product type and the optional
    /// name to generate a unique hash value for the `RegistrationKey`.
    ///
    /// - Parameter hasher: The hasher to use for combining the components.
    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.productType).hash(into: &hasher)
        self.name?.hash(into: &hasher)
    }
}

extension RegistrationKey: Equatable {
    /// Checks if two `RegistrationKey` instances are equal.
    ///
    /// This function compares the product type and the optional name of two
    /// `RegistrationKey` instances to determine if they are equal.
    ///
    /// - Parameters:
    ///     - lhs: The left-hand side key.
    ///     - rhs: The right-hand side key.
    /// - Returns: `true` if the keys are equal, `false` otherwise.
    static func == (lhs: RegistrationKey, rhs: RegistrationKey) -> Bool {
        return lhs.productType == rhs.productType && lhs.name == rhs.name
    }
}
