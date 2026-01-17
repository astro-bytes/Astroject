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
    
    /// Returns the set of assemblies that this assembly depends on.
    ///
    /// Use `Assembly.requires([...])` to declare dependencies.
    /// Default implementation returns an empty set.
    func requiredAssemblies() -> Set<ObjectIdentifier>
    
    // MARK: - New Optional Hooks
    
    /// Optional hook that is called before registration occurs.
    ///
    /// Use this to perform any setup that needs to happen prior to `assemble(container:)`.
    func preassemble() throws
    
    /// Optional hook that is called after all assemblies have been applied.
    ///
    /// Use this to perform any post-setup logic, validation, or initial resolution
    /// that depends on other assemblies having been assembled.
    ///
    /// - parameter resolver: The resolver providing access to dependencies.
    func postAssemble(resolver: Resolver) throws
    
    // MARK: - Core Methods
    
    /// Configures dependencies within the provided `Container`.
    ///
    /// Implementations should register all factories and dependencies into the container here.
    ///
    /// - parameter container: The `Container` instance to configure.
    func assemble(container: Container) throws
    
    // MARK: - Deprecated Hooks
    
    /// Deprecated: Use `preassemble()` instead.
    @available(*, deprecated, message: "Use preassemble() instead")
    func preloaded() throws
    
    /// Deprecated: Use `postAssemble(resolver:)` instead.
    @available(*, deprecated, message: "Use postAssemble(resolver:) instead")
    func loaded(resolver: Resolver) throws
}

public extension Assembly {
    
    /// Convenience function to declare dependencies using an array of assembly types.
    ///
    /// Example:
    /// ```swift
    /// struct FeatureAssembly: Assembly {
    ///     static let dependencies = requires([CoreAssembly.self, NetworkingAssembly.self])
    ///
    ///     func requiredAssemblies() -> Set<ObjectIdentifier> { Self.dependencies }
    /// }
    /// ```
    ///
    /// - Parameter assemblies: An array of `Assembly.Type` representing required assemblies.
    /// - Returns: A set of `ObjectIdentifier` representing required assemblies.
    static func requires(_ assemblies: [Assembly.Type] = []) -> Set<ObjectIdentifier> {
        Set(assemblies.map(ObjectIdentifier.init))
    }
    
    /// Default implementation returns an empty set, meaning no required assemblies.
    func requiredAssemblies() -> Set<ObjectIdentifier> { Self.requires() }
    
    /// Default implementation of `preassemble()`, which does nothing.
    func preassemble() throws {}
    
    /// Default implementation of `postAssemble(resolver:)`, which does nothing.
    func postAssemble(resolver: Resolver) throws {}
    
    /// Default implementation of deprecated `preloaded()`.
    @available(*, deprecated, message: "Use preassemble() instead")
    func preloaded() throws { try preassemble() }
    
    /// Default implementation of deprecated `loaded(resolver:)`.
    @available(*, deprecated, message: "Use postAssemble(resolver:) instead")
    func loaded(resolver: Resolver) throws { try postAssemble(resolver: resolver) }
}
