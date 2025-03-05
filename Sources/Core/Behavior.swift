//
// Behavior.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// Protocol for adding custom behavior to the `Container` during registration.
///
/// Implement this protocol to add custom logic that is executed after a registration
/// is added to the dependency injection container.
/// This can be useful for logging, analytics, or other side effects related to the registration process.
public protocol Behavior {
    /// Called after a registration has been added to the `Container`.
    ///
    /// - Parameters:
    ///   - type: The type of the product being registered.
    ///   - container: The `Container` instance to which the registration was added.
    ///   - registration: The `Registrable` instance that was added.
    ///   - name: An optional name associated with the registration.
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    )
}
