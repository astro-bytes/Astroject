//
//  Assembler.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Assembles dependencies into a `Container` using provided `Assembly` instances.
public class Assembler {
    /// The `Container` instance that dependencies are assembled into.
    let container: Container
    
    /// A `Resolver` instance that provides access to the assembled dependencies.
    var resolver: Resolver { container }
    
    /// Initializes an `Assembler` with a given `Container`.
    ///
    /// - Parameter container: The `Container` instance to assemble dependencies into.
    init(container: Container) {
        self.container = container
    }
    
    /// Applies a single `Assembly` to the `Container`.
    ///
    /// - Parameter assembly: The `Assembly` instance to apply.
    public func apply(assembly: Assembly) {
        run(assemblies: [assembly])
    }
    
    /// Applies an array of `Assembly` instances to the `Container`.
    ///
    /// - Parameter assemblies: The array of `Assembly` instances to apply.
    public func apply(assemblies: [Assembly]) {
        run(assemblies: assemblies)
    }
    
    /// Runs the assembly process for an array of `Assembly` instances.
    ///
    /// - Parameter assemblies: The array of `Assembly` instances to run.
    func run(assemblies: [Assembly]) {
        assemblies.forEach { $0.assemble(container: container) }
        assemblies.forEach { $0.loaded(resolver: resolver) }
    }
}
