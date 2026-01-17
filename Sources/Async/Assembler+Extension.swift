//
// Assembler+Extension.swift
// Astroject
//
// Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

/// Extension providing convenience initializers for `Assembler` using an asynchronous container.
///
/// These initializers allow quick construction of an `Assembler` with a default or custom
/// asynchronous container, and optionally register one or more `Assembly` instances during initialization.
public extension Assembler {
    
    /// Creates an `Assembler` using the specified asynchronous container.
    ///
    /// This initializer is useful when you want to manually configure the container
    /// or resolve dependencies asynchronously without registering any assemblies immediately.
    ///
    /// - Parameter container: The `Container` instance to associate with the assembler.
    ///   Defaults to a new instance of `AsyncContainer`.
    convenience init(_ container: Container = AsyncContainer()) {
        self.init(container: container)
    }
    
    /// Creates an `Assembler` and registers a list of `Assembly` instances using the specified
    /// asynchronous container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assemblies:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assemblies: An array of `Assembly` instances to register.
    ///   - container: The asynchronous `Container` to register the assemblies into.
    ///     Defaults to a new `AsyncContainer`.
    /// - Throws: Any error thrown by the assemblies during registration.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assemblies:) + assemble() instead")
    convenience init(_ assemblies: [Assembly], container: Container = AsyncContainer()) throws {
        try self.init(assemblies: assemblies, container: container)
    }
    
    /// Creates an `Assembler` and registers a single `Assembly` instance using the specified
    /// asynchronous container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assembly:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assembly: An `Assembly` instance to register.
    ///   - container: The asynchronous `Container` to register the assembly into.
    ///     Defaults to a new `AsyncContainer`.
    /// - Throws: Any error thrown by the assembly during registration.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assembly:) + assemble() instead")
    convenience init(_ assembly: Assembly, container: Container = AsyncContainer()) throws {
        try self.init(assembly: assembly, container: container)
    }
}
