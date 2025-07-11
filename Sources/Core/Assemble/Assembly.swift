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
    /// Performs any necessary setup or loading that needs to occur *before* the assembly's dependencies are registered.
    ///
    /// This function is typically used for tasks that must be completed prior to the main `assemble` phase,
    /// such as loading configuration files or initializing external systems that the assembly depends on.
    func preloaded() throws
    
    /// Configures dependencies within the provided `Container`.
    ///
    /// This function is called by an `Assembler` to register dependencies in the given `Container`.
    /// Implementations should use the `Container` to register factories and other configuration.
    ///
    /// - parameter container: The `Container` instance to configure.
    func assemble(container: Container) throws
    
    /// Called after the assembly has been loaded into the `Container`.
    ///
    /// This function is called by an `Assembler` after all assemblies have been processed.
    /// It allows performing any post-registration setup or configuration that requires access to
    /// the resolved dependencies.
    ///
    /// - parameter resolver: The `Resolver` instance providing access to the assembled dependencies.
    func loaded(resolver: Resolver) throws
}

public extension Assembly {
    /// Default implementation of `preloaded()`, which does nothing.
    ///
    /// This default implementation is provided for convenience, allowing assemblies
    /// that do not require pre-assembly setup to omit implementing the `preloaded` function.
    func preloaded() throws {}
    
    /// Default implementation of `loaded(resolver:)`, which does nothing.
    ///
    /// This default implementation is provided for convenience, allowing assemblies
    /// that do not require post-registration setup to omit implementing the `loaded` function.
    ///
    /// - parameter resolver: The `Resolver` instance (unused in the default implementation).
    func loaded(resolver: Resolver) throws {}
}
