//
// Assembler.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// Manages the assembly of dependencies into a `Container` using `Assembly` instances.
///
/// `Assembler` is responsible for applying one or more `Assembly` instances to a `Container`,
/// which registers dependencies and performs necessary setup. This class combines legacy
/// functionality with modern assembly validation.
public class Assembler {
    
    /// Errors that may occur during assembly.
    public enum Error: Swift.Error {
        /// Thrown when attempting to assemble dependencies that are already assembled.
        case alreadyAssembled
        /// Thrown when required assemblies are missing.
        case missingRequiredAssemblies
        /// Thrown when an operation requires the assemblies to be assembled first
        /// but `assemble()` has not yet been called.
        case notAssembled
    }
    
    /// The container that holds assembled dependencies.
    public let container: Container
    
    /// Resolver that provides access to the assembled dependencies.
    ///
    /// Returns the `Container` itself, as it conforms to the `Resolver` protocol.
    public var resolver: Resolver { container }
    
    /// Indicates whether the assembler has already assembled its dependencies.
    var isAssembled: Bool = false
    
    /// Assemblies that will be applied to the container.
    var assemblies: [Assembly]
    
    // MARK: - Initializers
    
    /// Creates an assembler with a container and an optional array of assemblies.
    ///
    /// If assemblies are provided, the assembler will immediately attempt to assemble them.
    ///
    /// - Parameters:
    ///   - container: The container to assemble dependencies into.
    ///   - assemblies: An array of `Assembly` instances to apply. Defaults to an empty array.
    /// - Throws: `Assembler.Error.alreadyAssembled` or `Assembler.Error.missingRequiredAssemblies` if validation fails.
    public init(container: Container, assemblies: [Assembly]) throws {
        self.container = container
        self.assemblies = assemblies
        if !assemblies.isEmpty {
            try self.assemble()
        }
    }
    
    /// Creates an assembler with only a container.
    ///
    /// Dependencies can be added later using `add(assembly:)` or `add(assemblies:)`.
    ///
    /// - Parameter container: The container to assemble dependencies into.
    public convenience init(container: Container) {
        // swiftlint:disable:next force_try
        try! self.init(container: container, assemblies: [])
    }
    
    // MARK: - Legacy Initializers
    
    /// Initializes an assembler with an array of assemblies and a container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assemblies:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assemblies: An array of assemblies to apply.
    ///   - container: The container to assemble dependencies into.
    /// - Throws: Any errors thrown by assembly.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assemblies:) + assemble() instead")
    public convenience init(assemblies: [Assembly], container: Container) throws {
        self.init(container: container)
        try self.add(assemblies: assemblies).assemble()
    }
    
    /// Initializes an assembler with a single assembly and a container (legacy API).
    ///
    /// Deprecated: Use `Assembler(container:)` + `add(assembly:)` + `assemble()` instead.
    ///
    /// - Parameters:
    ///   - assembly: The assembly to apply.
    ///   - container: The container to assemble dependencies into.
    /// - Throws: Any errors thrown by assembly.
    @available(*, deprecated, message: "Use Assembler(container:) + add(assembly:) + assemble() instead")
    public convenience init(assembly: Assembly, container: Container) throws {
        try self.init(assemblies: [assembly], container: container)
    }
    
    // MARK: - Assembly Management
    
    /// Adds a single assembly to the assembler.
    ///
    /// Adding an assembly marks the assembler as needing reassembly.
    /// Returns the assembler instance to allow method chaining.
    ///
    /// Example:
    /// ```swift
    /// try assembler.add(assembly: SomeAssembly())
    ///              .add(assembly: AnotherAssembly())
    ///              .assemble()
    /// ```
    ///
    /// - Parameter assembly: The `Assembly` instance to add.
    /// - Returns: The `Assembler` instance for chaining.
    @discardableResult
    public func add(assembly: Assembly) -> Assembler {
        return self.add(assemblies: [assembly])
    }
    
    /// Adds multiple assemblies to the assembler.
    ///
    /// Adding assemblies marks the assembler as needing reassembly.
    /// Returns the assembler instance to allow method chaining.
    ///
    /// Example:
    /// ```swift
    /// try assembler.add(assemblies: [AssemblyA(), AssemblyB()])
    ///              .assemble()
    /// ```
    ///
    /// - Parameter assemblies: An array of `Assembly` instances to add.
    /// - Returns: The `Assembler` instance for chaining.
    @discardableResult
    public func add(assemblies: [Assembly]) -> Assembler {
        self.assemblies += assemblies
        self.isAssembled = false
        return self
    }
    
    /// Validates and assembles all added assemblies into the container.
    ///
    /// - Throws: `Assembler.Error.alreadyAssembled` if already assembled, or
    ///           `Assembler.Error.missingRequiredAssemblies` if required
    ///           assemblies are missing.
    /// - Returns: The `Assembler` instance for chaining.
    @discardableResult
    public func assemble() throws -> Assembler {
        guard !self.isAssembled else {
            throw Self.Error.alreadyAssembled
        }
        
        guard !assemblies.isEmpty else { return self }
        
        try self.validateRequiredAssemblies()
        try self.run()
        self.isAssembled = true
        return self
    }
    
    /// Validates that all required assemblies are present before assembly.
    ///
    /// - Throws: `Assembler.Error.missingRequiredAssemblies` if any required assembly is missing.
    func validateRequiredAssemblies() throws {
        let presentTypes = Set(self.assemblies.map { ObjectIdentifier(type(of: $0)) })
        let requiredTypes = Set(self.assemblies.flatMap { $0.requiredAssemblies() })
        
        guard requiredTypes.isSubset(of: presentTypes) else {
            throw Self.Error.missingRequiredAssemblies
        }
    }
    
    /// Runs the assembly process for all assemblies.
    ///
    /// This involves three phases for each assembly:
    /// 1. `preloaded()` — pre-assembly configuration.
    /// 2. `assemble(container:)` — registers dependencies into the container.
    /// 3. `loaded(resolver:)` — post-assembly configuration.
    ///
    /// - Throws: Any errors thrown by the assemblies.
    func run() throws {
        try self.assemblies.forEach {
            try $0.preassemble()
            try $0.preloaded()
        }
        
        try self.assemblies.forEach { try $0.assemble(container: self.container) }
        
        try self.assemblies.forEach {
            try $0.postAssemble(resolver: self.resolver)
            try $0.loaded(resolver: self.resolver)
        }
    }
    
    // MARK: - Legacy Compatibility
    
    /// Applies a single assembly to the container (legacy API).
    ///
    /// Deprecated: Use `add(assembly:)` + `assemble()` instead.
    ///
    /// - Parameter assembly: The assembly to apply.
    @available(*, deprecated, message: "Use add(assembly:) followed by assemble() instead")
    public func apply(assembly: Assembly) throws {
        try run(assemblies: [assembly])
    }
    
    /// Applies multiple assemblies to the container (legacy API).
    ///
    /// Deprecated: Use `add(assemblies:)` followed by `assemble()` instead.
    ///
    /// - Parameter assemblies: The assemblies to apply.
    @available(*, deprecated, message: "Use add(assemblies:) followed by assemble() instead")
    public func apply(assemblies: [Assembly]) throws {
        try run(assemblies: assemblies)
    }
    
    /// Runs a set of assemblies without affecting `self.assemblies`.
    ///
    /// Used internally and for legacy API.
    ///
    /// - Parameter assemblies: The assemblies to run.
    /// - Throws: Any errors thrown by the assemblies.
    @available(*, deprecated, message: "Internal use only; use assemble() for modern usage")
    func run(assemblies: [Assembly]) throws {
        try assemblies.forEach {
            try $0.preassemble()
            try $0.preloaded()
        }
        
        try assemblies.forEach { try $0.assemble(container: self.container) }
        
        try assemblies
            .forEach {
                try $0.postAssemble(resolver: self.resolver)
                try $0.loaded(resolver: resolver)
            }
    }
}
