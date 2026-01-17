//
// Assembler+Extension.swift
// Astroject
//
// Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

/// Extension providing convenience initializers for `Assembler`.
///
/// These initializers streamline common scenarios by allowing quick construction
/// of an `Assembler` with a default or custom container, and optionally register
/// one or more `Assembly` instances during initialization.
public extension Assembler {
    
    /// Creates an `Assembler` using the specified container.
    ///
    /// This initializer is useful when you want to manually configure the container
    /// or resolve dependencies without registering any assemblies immediately.
    ///
    /// - Parameter container: The `Container` instance to associate with the assembler.
    ///   Defaults to a new instance of `SyncContainer`.
    convenience init(_ container: Container = SyncContainer()) {
        self.init(container: container)
    }
    
    /// Creates an `Assembler` and registers a list of `Assembly` instances using the specified container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assemblies:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assemblies: An array of `Assembly` instances to register.
    ///   - container: The `Container` to register the assemblies into. Defaults to a new `SyncContainer`.
    /// - Throws: Any error thrown by the assemblies during registration.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assemblies:) + assemble() instead")
    convenience init(_ assemblies: [Assembly], container: Container = SyncContainer()) throws {
        try self.init(assemblies: assemblies, container: container)
    }
    
    /// Creates an `Assembler` and registers a single `Assembly` instance using the specified container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assembly:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assembly: An `Assembly` instance to register.
    ///   - container: The `Container` to register the assembly into. Defaults to a new `SyncContainer`.
    /// - Throws: Any error thrown by the assembly during registration.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assembly:) + assemble() instead")
    convenience init(_ assembly: Assembly, container: Container = SyncContainer()) throws {
        try self.init(assembly: assembly, container: container)
    }
}
