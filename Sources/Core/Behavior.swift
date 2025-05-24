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
    /// - parameter type: The type of the product being registered.
    /// - parameter container: The `Container` instance to which the registration was added.
    /// - parameter registration: The `Registrable` instance that was added.
    /// - parameter name: An optional name associated with the registration.
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    )

    /// Called after a product has been successfully resolved from the `Container`.
    ///
    /// This function provides a hook to perform actions immediately after an instance
    /// of a registered product is created and returned by the resolver. This can be useful
    /// for logging successful resolutions, performing post-resolution validation,
    /// or triggering other related processes.
    ///
    /// - parameter type: The type of the product that was resolved.
    /// - parameter container: The `Container` instance from which the product was resolved.
    /// - parameter registration: The `Registrable` instance used for the resolution.
    /// - parameter name: An optional name associated with the resolved registration.
    func didResolve<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    )
}
