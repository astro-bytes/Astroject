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
/// which registers dependencies and performs necessary setup.
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
            case (
                .requiredAssemblyOutsideEnvironment(let leftAssembly, let leftRequired, let leftEnvironment),
                .requiredAssemblyOutsideEnvironment(let rightAssembly, let rightRequired, let rightEnvironment)
            ):
                return leftAssembly == rightAssembly
                    && leftRequired == rightRequired
                    && leftEnvironment == rightEnvironment
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
        
        /// Thrown when an assembly that runs in the assembler's environment requires an
        /// assembly whose `environments` leave it out.
        ///
        /// For example, a `FeatureAssembly` that runs everywhere can't require a
        /// `StubsAssembly` that only runs in `.test` when the environment is `.release`.
        case requiredAssemblyOutsideEnvironment(
            assembly: String,
            required: String,
            environment: AstrojectEnvironment
        )
    }
    
    /// The container that holds assembled dependencies.
    public let container: Container
    
    /// The environment the app is running in, or `nil` to run every assembly.
    ///
    /// The assembler skips assemblies whose `environments` don't contain it.
    public let environment: AstrojectEnvironment?
    
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
    public private(set) var isAssembled: Bool = false
    
    /// Whether `assemble()` writes a report of overridden registrations to the console.
    ///
    /// Registration is last one wins. After assembling, the assembler lists every key that was
    /// registered more than once, where each registration came from, and which one wins, through
    /// `os.Logger` with the subsystem `Astroject`. Nothing is written when no key was overridden.
    ///
    /// Defaults to `true` for the `.debug` and `.test` environments and `false` for `.release`.
    /// With a custom environment or none, it defaults to `true` when Astroject is built for debug.
    public lazy var logsOverrides: Bool = Assembler.logsOverridesByDefault(in: environment)
    
    /// Assemblies that will be applied to the container.
    private(set) var assemblies: [Assembly]
    
    // MARK: - Initializers
    
    /// Creates an assembler with a container and an optional array of assemblies.
    ///
    /// If assemblies are provided, the assembler will immediately attempt to assemble them.
    ///
    /// - Parameters:
    ///   - container: The container to assemble dependencies into.
    ///   - environment: The environment the app is running in, or `nil` to run every assembly. Defaults to `nil`.
    ///   - assemblies: An array of `Assembly` instances to apply.
    ///   - initializeMissingAssemblies: A flag indicating whether to automatically initialize
    ///     and add any required assemblies that are missing when `assemble()` is called. Defaults to `true`.
    /// - Throws: `Assembler.Error.missingRequiredAssemblies`, `Assembler.Error.circularDependency`,
    ///   or `Assembler.Error.assemblyFailure` if validation or assembly fails.
    public init(
        container: Container,
        environment: AstrojectEnvironment? = nil,
        assemblies: [Assembly],
        initializeMissingAssemblies: Bool = true
    ) throws {
        self.container = container
        self.environment = environment
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
    /// - Parameter environment: The environment the app is running in, or `nil` to run every assembly.
    ///     Defaults to `nil`.
    /// - Parameter initializeMissingAssemblies: A flag indicating whether to automatically initialize
    ///     and add any required assemblies that are missing when `assemble()` is called. Defaults to `true`.
    public init(
        container: Container,
        environment: AstrojectEnvironment? = nil,
        initializeMissingAssemblies: Bool = true
    ) {
        self.container = container
        self.environment = environment
        self.assemblies = []
        self.initializeMissingAssemblies = initializeMissingAssemblies
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
        self.logOverridesIfNeeded()
        return self
    }
    
    /// Validates that all required assemblies declared by each assembly are present,
    /// and orders the assemblies so every assembly runs after the assemblies it requires.
    ///
    /// This method performs a **recursive check** of each assembly's `requiredAssemblies`,
    /// ensuring that all dependencies, including transitive ones, are present in the assembler.
    ///
    /// If `initializeMissingAssemblies` is `true`, any missing assemblies are automatically
    /// instantiated. If `false`, a `missingRequiredAssemblies` error is thrown listing all
    /// missing assemblies.
    ///
    /// Registration is last one wins, so order matters. After validation, `assemblies` is
    /// sorted so that each assembly comes after everything in its `requiredAssemblies`
    /// (including auto-initialized ones). Apart from that constraint, the order the
    /// assemblies were added in is kept.
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
        // Assemblies already present, grouped by type in the order they were added
        // Assemblies outside the environment are skipped
        let included = assemblies.filter { isIncluded(type(of: $0)) }
        
        var present: [ObjectIdentifier: [Assembly]] = [:]
        for assembly in included {
            present[ObjectIdentifier(type(of: assembly)), default: []].append(assembly)
        }
        
        // The final order: each entry is either the present instances of a type,
        // or a missing type that still has to be initialized.
        enum Step {
            case present([Assembly])
            case missing(Assembly.Type)
        }
        var steps: [Step] = []
        var missingTypes: [Assembly.Type] = []
        
        // Cycle detection helpers
        var visitingStack: [Assembly.Type] = [] // current recursion path, kept for the error message
        var visiting = Set<ObjectIdentifier>()  // the same path, for O(1) cycle checks
        var visited = Set<ObjectIdentifier>()   // visited nodes
        
        // Recursive visit function (post-order: requirements are emitted before the assembly)
        func visit(_ assemblyType: Assembly.Type) throws(Assembler.Error) {
            // Detect circular dependency
            let id = ObjectIdentifier(assemblyType)
            if visiting.contains(id) {
                let cycle = visitingStack.map { String(describing: $0) } + [String(describing: assemblyType)]
                throw Assembler.Error.circularDependency(cycle)
            }
            
            guard !visited.contains(id) else { return } // already processed
            
            visited.insert(id)
            visitingStack.append(assemblyType)
            visiting.insert(id)
            
            // Recursively visit required assemblies first
            for dep in assemblyType.requiredAssemblies {
                if let environment, !isIncluded(dep) {
                    throw Assembler.Error.requiredAssemblyOutsideEnvironment(
                        assembly: String(describing: assemblyType),
                        required: String(describing: dep),
                        environment: environment
                    )
                }
                try visit(dep)
            }
            
            visitingStack.removeLast()
            visiting.remove(id)
            
            // Emit this assembly after its requirements
            if let instances = present[id] {
                steps.append(.present(instances))
            } else {
                missingTypes.append(assemblyType)
                steps.append(.missing(assemblyType))
            }
        }
        
        // Start visiting all assemblies in the order they were added
        for assembly in included {
            try visit(type(of: assembly))
        }
        
        // If auto-init is disabled, throw an error for missing assemblies
        if !initializeMissingAssemblies, !missingTypes.isEmpty {
            let missingNames = missingTypes.map { String(describing: $0) }.sorted()
            throw Assembler.Error.missingRequiredAssemblies(missingNames)
        }
        
        // Build the ordered list, instantiating missing assemblies in place
        assemblies = steps.flatMap { step -> [Assembly] in
            switch step {
            case .present(let instances):
                return instances
            case .missing(let assemblyType):
                return [assemblyType.init()]
            }
        }
    }
    
    /// Runs the assembly process for all assemblies.
    ///
    /// For each assembly, the following lifecycle is executed in order:
    ///
    /// 1. `preassemble()`
    /// 2. `assemble(container:)`
    /// 3. `postAssemble(resolver:)`
    ///
    /// - Throws: Any error thrown by an assembly hook.
    func run() throws(Assembler.Error) {
        do {
            try self.assemblies.forEach { try $0.preassemble() }
            
            try self.assemblies.forEach { assembly in
                try RegistrationSource.$currentAssembly.withValue(String(describing: type(of: assembly))) {
                    try assembly.assemble(container: self.container)
                }
            }
            
            try self.assemblies.forEach { try $0.postAssemble(resolver: self.resolver) }
        } catch {
            throw Self.Error.assemblyFailure(error)
        }
    }
    
    /// Writes the report of overridden registrations when `logsOverrides` is on and a key was overridden.
    func logOverridesIfNeeded() {
        guard logsOverrides else { return }
        let report = container.registrationReport()
        guard !report.overridden.isEmpty else { return }
        report.log()
    }
    
    /// Whether `assembly` runs in this assembler's environment.
    func isIncluded(_ assembly: Assembly.Type) -> Bool {
        guard let environment, let environments = assembly.environments else { return true }
        return environments.contains(environment)
    }
    
    /// Whether overrides are logged by default in `environment`.
    static func logsOverridesByDefault(in environment: AstrojectEnvironment?) -> Bool {
        switch environment {
        case .debug, .test: true
        case .release: false
        case .custom, nil: isDebugBuild
        }
    }
    
    /// Whether this library was built in the debug configuration.
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
