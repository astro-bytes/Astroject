//
// Assembly.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// A protocol defining an assembly that configures dependencies in a `Container`.
///
/// The `Assembly` protocol is used to define a set of instructions for configuring
/// dependencies within a dependency injection `Container`.
/// Implementations of this protocol are responsible for registering dependencies and performing any necessary setup.
public protocol Assembly {
    /// Configures dependencies within the provided `Container`.
    ///
    /// This function is called by an `Assembler` to register dependencies in the given `Container`.
    /// Implementations should use the `Container` to register factories and other configuration.
    ///
    /// - Parameter container: The `Container` instance to configure.
    func assemble(container: Container)
    
    /// Called after the assembly has been loaded into the `Container`.
    ///
    /// This function is called by an `Assembler` after all assemblies have been processed.
    /// It allows performing any post-registration setup or configuration that requires access to
    /// the resolved dependencies.
    ///
    /// - Parameter resolver: The `Resolver` instance providing access to the assembled dependencies.
    func loaded(resolver: Resolver)
}

public extension Assembly {
    /// Default implementation of `loaded(resolver:)`, which does nothing.
    ///
    /// This default implementation is provided for convenience, allowing assemblies
    /// that do not require post-registration setup to omit implementing the `loaded` function.
    ///
    /// - Parameter resolver: The `Resolver` instance (unused in the default implementation).
    func loaded(resolver: Resolver) {}
}
