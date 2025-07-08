//
//  Assembler+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

/// Extension providing convenience initializers for `Assembler`.
///
/// These initializers are designed to streamline common scenarios by allowing you
/// to quickly construct an `Assembler` with a default or custom container,
/// and optionally register one or more `Assembly` instances during initialization.
public extension Assembler {
    
    /// Creates an `Assembler` using the specified container.
    ///
    /// This initializer is useful when you want to manually configure the container
    /// or resolve dependencies without registering any assemblies immediately.
    ///
    /// - Parameter container: The `Container` instance to associate with the assembler.
    ///   Defaults to a new instance of `SyncContainer`, which performs synchronous dependency resolution.
    convenience init(_ container: Container = SyncContainer()) {
        self.init(container: container)
    }
    
    /// Creates an `Assembler` and registers a list of `Assembly` instances using the specified container.
    ///
    /// This initializer is ideal for bulk registration of services at launch, such as when composing
    /// feature modules or building your application’s dependency graph.
    ///
    /// - Parameters:
    ///   - assemblies: An array of `Assembly` instances, each responsible for registering
    ///     a set of dependencies into the container.
    ///   - container: The `Container` to register the assemblies into. Defaults to a new `SyncContainer`.
    /// - Throws: An error if any of the `Assembly` instances throw during their `register(in:)` call.
    convenience init(_ assemblies: [Assembly], container: Container = SyncContainer()) throws {
        try self.init(assemblies: assemblies, container: container)
    }
    
    /// Creates an `Assembler` and registers a single `Assembly` instance using the specified container.
    ///
    /// This initializer is a convenience for registering just one module or feature’s dependencies.
    /// It is functionally similar to passing a single-element array to the other initializer.
    ///
    /// - Parameters:
    ///   - assembly: An `Assembly` instance responsible for registering dependencies into the container.
    ///   - container: The `Container` to register the assembly into. Defaults to a new `SyncContainer`.
    /// - Throws: An error if the `Assembly` instance throws during its `register(in:)` call.
    convenience init(_ assembly: Assembly, container: Container =  SyncContainer()) throws {
        try self.init(assembly: assembly, container: container)
    }
}
