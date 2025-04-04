//
// Assembler.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// Assembles dependencies into a `Container` using provided `Assembly` instances.
///
/// The `Assembler` class is responsible for applying one or more `Assembly` instances to a `Container`,
/// which registers dependencies and performs any necessary setup.
public class Assembler {
    /// The `Container` instance that dependencies are assembled into.
    let container: Container
    
    /// A `Resolver` instance that provides access to the assembled dependencies.
    /// This property returns the `Container` itself, as it conforms to the `Resolver` protocol.
    var resolver: Resolver { container }
    
    /// Initializes an `Assembler` with a given `Container`.
    ///
    /// - parameter container: The `Container` instance to assemble dependencies into.
    public init(container: Container) {
        self.container = container
    }
    
    /// Applies a single `Assembly` to the `Container`.
    ///
    /// This function applies the `assemble` and `loaded` methods of the provided `Assembly` instance.
    ///
    /// - parameter assembly: The `Assembly` instance to apply.
    public func apply(assembly: Assembly) {
        run(assemblies: [assembly])
    }
    
    /// Applies an array of `Assembly` instances to the `Container`.
    ///
    /// This function applies the `assemble` and `loaded` methods of each `Assembly` instance in the provided array.
    ///
    /// - parameter assemblies: The array of `Assembly` instances to apply.
    public func apply(assemblies: [Assembly]) {
        run(assemblies: assemblies)
    }
    
    /// Runs the assembly process for an array of `Assembly` instances.
    ///
    /// This function iterates through the provided array of `Assembly` instances
    /// and calls their `assemble` and `loaded` methods.
    /// The `assemble` method registers dependencies in the `Container`,
    /// and the `loaded` method performs any post-registration setup.
    ///
    /// - parameter assemblies: The array of `Assembly` instances to run.
    func run(assemblies: [Assembly]) {
        // Iterate through the assemblies and call the assemble method on each one to register the dependencies.
        assemblies.forEach { $0.assemble(container: container) }
        // Iterate through the assemblies again and call the loaded
        // method on each one to perform any post-registration configuration.
        assemblies.forEach { $0.loaded(resolver: resolver) }
    }
}
