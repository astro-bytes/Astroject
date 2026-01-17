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
    public enum Error: Swift.Error, Equatable {
        public static func == (lhs: Assembler.Error, rhs: Assembler.Error) -> Bool {
            switch (lhs, rhs) {
            case (.alreadyAssembled, .alreadyAssembled), (.notAssembled, .notAssembled):
                return true
            case (
                .missingRequiredAssemblies(let left),
                .missingRequiredAssemblies(let right)
            ),
                (
                    .circularDependency(let left),
                    .circularDependency(let right)
                ):
                return left == right
            case (.assemblyFailure(let left), .assemblyFailure(let right)):
                return String(describing: left) == String(describing: right)
            default:
                return false
            }
        }
        /// Thrown when `assemble()` is called but the assembler has already completed assembly.
        /// Assemblies can only be assembled as many times as necessary if an assembly is added but
        /// not applied per Assembler instance.
        case alreadyAssembled
        
        /// Thrown when one or more assemblies declare dependencies that are not present
        /// in the Assembler. The associated array contains the missing assembly type names.
        case missingRequiredAssemblies([String])
        
        /// Thrown when a circular dependency between assemblies is detected.
        ///
        /// The associated array contains the names of the assemblies forming the cycle,
        /// starting and ending with the same assembly to show the loop.
        case circularDependency([String])
        
        /// Thrown when an operation requires the assemblies to have been assembled first,
        /// but `assemble()` has not yet been called. For example, resolving dependencies
        /// before assembly will trigger this error.
        case notAssembled
        
        /// Thrown when an assembly throws an unexpected error during its lifecycle methods
        /// (`preassemble()`, `assemble(container:)`, or `postAssemble(resolver:)`).
        ///
        /// The associated `Swift.Error` contains the original error thrown by the assembly,
        /// allowing the caller to inspect or propagate the underlying cause.
        case assemblyFailure(Swift.Error)
    }
    
    /// The container that holds assembled dependencies.
    public let container: Container
    
    /// Resolver that provides access to the assembled dependencies.
    ///
    /// Returns the `Container` itself, as it conforms to the `Resolver` protocol.
    public var resolver: Resolver { container }
    
    /// Indicates whether the assembler should automatically create and add any assemblies
    /// that are required but not present in the assembler when `assemble()` is called.
    ///
    /// - true: Missing required assemblies are instantiated and added automatically.
    /// - false: Missing assemblies cause `assemble()` to throw `Assembler.Error.missingRequiredAssemblies`.
    let initializeMissingAssemblies: Bool
    
    /// Indicates whether the assembler has already completed assembly.
    ///
    /// Once `assemble()` has successfully run, attempting to assemble again
    /// will throw `Assembler.Error.alreadyAssembled`.
    private(set) var isAssembled: Bool = false
    
    /// Assemblies that will be applied to the container.
    private(set) var assemblies: [Assembly]
    
    // MARK: - Initializers
    
    /// Creates an assembler with a container and an optional array of assemblies.
    ///
    /// If assemblies are provided, the assembler will immediately attempt to assemble them.
    ///
    /// - Parameters:
    ///   - container: The container to assemble dependencies into.
    ///   - assemblies: An array of `Assembly` instances to apply. Defaults to an empty array.
    /// - Throws: `Assembler.Error.missingRequiredAssemblies`, `Assembler.Error.circularDependency`,
    ///   or `Assembler.Error.assemblyFailure` if validation or assembly fails.
    public init(container: Container, assemblies: [Assembly], initializeMissingAssemblies: Bool = true) throws {
        self.container = container
        self.assemblies = assemblies
        self.initializeMissingAssemblies = initializeMissingAssemblies
        if !assemblies.isEmpty {
            try self.assemble()
        }
    }
    
    /// Creates an assembler with only a container.
    ///
    /// Dependencies can be added later using `add(assembly:)` or `add(assemblies:)`.
    ///
    /// - Parameter container: The container to assemble dependencies into.
    public init(container: Container, initializeMissingAssemblies: Bool = true) {
        self.container = container
        self.assemblies = []
        self.initializeMissingAssemblies = initializeMissingAssemblies
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
    /// - Throws:
    ///   - `Assembler.Error.alreadyAssembled` if the assembler has already completed assembly.
    ///   - `Assembler.Error.missingRequiredAssemblies` if required assemblies are missing and
    ///     auto-initialization is disabled.
    ///   - `Assembler.Error.circularDependency` if a circular dependency between assemblies is detected.
    ///   - `Assembler.Error.assemblyFailure` if an assembly lifecycle method throws an error.
    /// - Returns: The `Assembler` instance for chaining.
    @discardableResult
    public func assemble() throws(Assembler.Error) -> Assembler {
        guard !self.isAssembled else {
            throw Self.Error.alreadyAssembled
        }
        
        guard !assemblies.isEmpty else { return self }
        
        try self.validateRequiredAssemblies()
        try self.run()
        self.isAssembled = true
        return self
    }
    
    /// Validates that all required assemblies declared by each assembly are present.
    ///
    /// This method performs a **recursive check** of each assembly's `requiredAssemblies`,
    /// ensuring that all dependencies, including transitive ones, are present in the assembler.
    ///
    /// If `initializeMissingAssemblies` is `true`, any missing assemblies are automatically
    /// instantiated and appended to the assembler. If `false`, a `missingRequiredAssemblies`
    /// error is thrown listing all missing assemblies.
    ///
    /// Additionally, this function detects **circular dependencies** between assemblies.
    /// If a cycle is detected, a `circularDependency` error is thrown containing
    /// the sequence of assemblies forming the cycle.
    ///
    /// Validation occurs before any assembly lifecycle methods (`preassemble`, `assemble`,
    /// `postAssemble`) are executed.
    ///
    /// - Throws:
    ///   - `Assembler.Error.missingRequiredAssemblies` if required assemblies are missing and
    ///     `initializeMissingAssemblies` is `false`.
    ///   - `Assembler.Error.circularDependency` if a circular dependency is detected.
    func validateRequiredAssemblies() throws(Assembler.Error) {
        // Assemblies already present
        var presentIdentifiers = Set(self.assemblies.map { ObjectIdentifier(type(of: $0)) })
        
        // Assemblies that are missing and will be auto-initialized
        var missingTypes: [Assembly.Type] = []
        
        // Cycle detection helpers
        var visitingStack: [Assembly.Type] = [] // stack to track current recursion path
        var visited = Set<ObjectIdentifier>()   // visited nodes
        
        // Recursive visit function
        func visit(_ assemblyType: Assembly.Type) throws(Assembler.Error) {
            // Detect circular dependency
            if visitingStack.contains(where: { $0 == assemblyType }) {
                let cycle = visitingStack.map { String(describing: $0) } + [String(describing: assemblyType)]
                throw Assembler.Error.circularDependency(cycle)
            }
            
            let id = ObjectIdentifier(assemblyType)
            guard !visited.contains(id) else { return } // already processed
            
            visited.insert(id)
            visitingStack.append(assemblyType)
            
            // Recursively visit required assemblies
            for dep in assemblyType.requiredAssemblies {
                try visit(dep)
            }
            
            visitingStack.removeLast()
            
            // Queue this assembly for adding if not already present
            if !presentIdentifiers.contains(id) {
                missingTypes.append(assemblyType)
                presentIdentifiers.insert(id)
            }
        }
        
        // Start visiting all assemblies currently in the assembler
        for assembly in assemblies {
            try visit(type(of: assembly))
        }
        
        // If auto-init is disabled, throw an error for missing assemblies
        if !initializeMissingAssemblies, !missingTypes.isEmpty {
            let missingNames = missingTypes.map { String(describing: $0) }.sorted()
            throw Assembler.Error.missingRequiredAssemblies(missingNames)
        }
        
        // Instantiate missing assemblies after recursion
        for missingType in missingTypes {
            let assembly = missingType.init()
            assemblies.append(assembly)
        }
    }
    
    /// Runs the assembly process for all assemblies.
    ///
    /// For each assembly, the following lifecycle is executed in order:
    ///
    /// 1. `preassemble()`
    /// 2. `preloaded()` (deprecated)
    /// 3. `assemble(container:)`
    /// 4. `postAssemble(resolver:)`
    /// 5. `loaded(resolver:)` (deprecated)
    ///
    /// - Throws: Any error thrown by an assembly hook.
    func run() throws(Assembler.Error) {
        do {
            try self.assemblies.forEach {
                try $0.preassemble()
                try $0.preloaded()
            }
            
            try self.assemblies.forEach { try $0.assemble(container: self.container) }
            
            try self.assemblies.forEach {
                try $0.postAssemble(resolver: self.resolver)
                try $0.loaded(resolver: self.resolver)
            }
        } catch {
            throw Self.Error.assemblyFailure(error)
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
