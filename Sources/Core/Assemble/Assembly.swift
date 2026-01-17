//
// Assembly.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// A protocol defining an assembly that configures dependencies in a `Container`.
///
/// An `Assembly` represents a modular unit of dependency registration.
/// Assemblies may optionally participate in pre- and post-assembly lifecycle hooks
/// and declare dependencies on other assemblies.
public protocol Assembly {
    
    /// Required default initializer.
    ///
    /// This initializer allows the Assembler to automatically create instances
    /// of assemblies when `initializeMissingAssemblies` is true and a required
    /// assembly is missing. All assemblies that may be automatically initialized
    /// must implement a public, parameterless `init()`.
    ///
    /// Example:
    /// ```swift
    /// struct FeatureAssembly: Assembly {
    ///     init() { /* default setup */ }
    /// }
    /// ```
    init()
    
    /// A list of assemblies that must also be present for this assembly to run.
    ///
    /// These dependencies are validated by the `Assembler` before assembly begins.
    /// Default implementation returns an empty array.
    var requiredAssemblies: [Assembly.Type] { get }
    
    // MARK: - Lifecycle Hooks
    
    /// Called before any dependencies are registered.
    ///
    /// Use this for validation or preparation that must occur prior to `assemble(container:)`.
    /// Default implementation does nothing.
    func preassemble() throws
    
    /// Called after all assemblies have completed registration.
    ///
    /// This hook is guaranteed to run after every assembly's `assemble(container:)`
    /// has executed.
    ///
    /// Use this for validation, resolving initial objects, or wiring
    /// that depends on the full dependency graph.
    func postAssemble(resolver: Resolver) throws
    
    // MARK: - Required Method
    
    /// Registers dependencies into the provided container.
    ///
    /// This method is required and is where all registrations should occur.
    func assemble(container: Container) throws
    
    // MARK: - Legacy Hooks
    
    /// Deprecated legacy pre-assembly hook.
    ///
    /// This method is still invoked after `preassemble()` for backward compatibility.
    @available(*, deprecated, message: "Use preassemble() instead")
    func preloaded() throws
    
    /// Deprecated legacy post-assembly hook.
    ///
    /// This method is still invoked after `postAssemble(resolver:)` for backward compatibility.
    @available(*, deprecated, message: "Use postAssemble(resolver:) instead")
    func loaded(resolver: Resolver) throws
}

public extension Assembly {
    /// Default implementation returns an empty set, meaning no required assemblies.
    var requiredAssemblies: [Assembly.Type] { [] }
    
    /// Default implementation of `preassemble()`, which does nothing.
    func preassemble() throws {}
    
    /// Default implementation of `postAssemble(resolver:)`, which does nothing.
    func postAssemble(resolver: Resolver) throws {}
    
    /// Default implementation of deprecated `preloaded()`.
    @available(*, deprecated, message: "Use preassemble() instead")
    func preloaded() throws {}
    
    /// Default implementation of deprecated `loaded(resolver:)`.
    @available(*, deprecated, message: "Use postAssemble(resolver:) instead")
    func loaded(resolver: Resolver) throws {}
}
