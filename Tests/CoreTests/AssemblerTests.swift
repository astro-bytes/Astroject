//
// AssemblerTests.swift
// Astroject
//
// Created by Porter McGary on 1/16/26.
//

import Testing
@testable import AstrojectCore
@testable import Mocks

// MARK: - Test Assemblies

struct NetworkingAssembly: Assembly {
    func assemble(container: Container) throws {}
}

struct FeatureAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] {[
        MockAssembly.self,
        NetworkingAssembly.self
    ]}
    
    func assemble(container: Container) throws {}
}

struct AnalyticsAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] {[ MockAssembly.self ]}
    func assemble(container: Container) throws {}
}

struct AAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [BAssembly.self] }
    func assemble(container: Container) throws {}
}

struct BAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [CAssembly.self] }
    func assemble(container: Container) throws {}
}

struct CAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [] }
    func assemble(container: Container) throws {}
}

struct CircularA: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [CircularB.self] }
    func assemble(container: Container) throws {}
}

struct CircularB: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [CircularA.self] }
    func assemble(container: Container) throws {}
}

struct SelfCycle: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [SelfCycle.self] }
    func assemble(container: Container) throws {}
}

// Deep dependency chain
struct DAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [EAssembly.self] }
    func assemble(container: Container) throws {}
}

struct EAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [] }
    func assemble(container: Container) throws {}
}

// Multiple branches
struct BranchA: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [BranchB.self, BranchC.self] }
    func assemble(container: Container) throws {}
}

struct BranchB: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [BranchD.self] }
    func assemble(container: Container) throws {}
}

struct BranchC: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [BranchD.self] }
    func assemble(container: Container) throws {}
}

struct BranchD: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [] }
    func assemble(container: Container) throws {}
}

// MARK: - Legacy Assembler Tests

@Suite("Legacy Assembler Tests")
struct LegacyAssemblerTests {
    
    @Test("Init with Container")
    func initWithContainer() {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(container === assembler.container)
        #expect(container === assembler.resolver)
    }
    
    @Test("Init with Assemblies")
    func initWithAssemblies() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        
        let assembler = try Assembler(assemblies: [assembly1, assembly2], container: container)
        
        #expect(assembler.container === container)
        #expect(assembler.resolver === container)
        #expect(assembly1.preassembleCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.postAssembleCalled)
    }
    
    @Test("Init with Assembly")
    func initWithAssembly() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        
        let assembler = try Assembler(assembly: assembly, container: container)
        
        #expect(assembler.container === container)
        #expect(assembler.resolver === container)
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
    }
    
    @Test("Apply Single Assembly")
    func applySingleAssembly() throws {
        let assembly = MockAssembly()
        let assembler = Assembler(container: MockContainer())
        
        try assembler.apply(assembly: assembly)
        
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
    }
    
    @Test("Apply Multiple Assemblies")
    func applyMultipleAssemblies() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.apply(assemblies: [assembly1, assembly2])
        
        #expect(assembly1.preassembleCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.postAssembleCalled)
        #expect(assembly2.preassembleCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembly2.postAssembleCalled)
    }
    
    @Test("Runs Assembly in Correct Sequence")
    func correctSequence() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        var sequence: [String] = []
        assembly.whenPreassemble = { sequence.append("preassembled") }
        assembly.whenAssemble = { sequence.append("assembled") }
        assembly.whenPostAssemble = { sequence.append("post-assembled") }
        
        let assembler = Assembler(container: container)
        try assembler.run(assemblies: [assembly])
        
        #expect(sequence == ["preassembled", "assembled", "post-assembled"])
    }
    
    @Test("Deprecated Initializer with Single Assembly")
    func deprecatedInitSingleAssembly() throws {
        let assembly = MockAssembly()
        let assembler = try Assembler(assembly: assembly, container: MockContainer())
        
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
        #expect(assembler.isAssembled)
    }
    
    @Test("Deprecated Initializer with Multiple Assemblies")
    func deprecatedInitMultipleAssemblies() throws {
        let assemblies = [MockAssembly(), MockAssembly()]
        let assembler = try Assembler(assemblies: assemblies, container: MockContainer())
        
        assemblies.forEach {
            #expect($0.preassembleCalled)
            #expect($0.assembleCalled)
            #expect($0.postAssembleCalled)
        }
        #expect(assembler.isAssembled)
    }
    
    @Test("Apply Single Assembly Calls Pre/Post Assemble")
    func applySingleAssemblyCallsPrePost() throws {
        let assembly = MockAssembly()
        let assembler = Assembler(container: MockContainer())
        
        try assembler.apply(assembly: assembly)
        
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
    }
}

// MARK: - Modern Assembler Tests

@Suite("Assembler Tests")
final class AssemblerTests {
    
    // MARK: Dependency validation tests
    
    @Test("Missing Assemblies Throws Error")
    func missingRequiredAssembliesThrows() throws {
        let container = MockContainer()
        let assembler = Assembler(
            container: container,
            initializeMissingAssemblies: false
        )
        let error = Assembler.Error.missingRequiredAssemblies([
            "MockAssembly", "NetworkingAssembly"
        ])
        
        #expect(throws: error) {
            try assembler.add(assemblies: [FeatureAssembly()]).assemble()
        }
    }
    
    @Test("Missing Assemblies Creates Missing Assemblies")
    func missingRequiredAssembliesCreatesMissingAssemblies() throws {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        assembler.add(assemblies: [FeatureAssembly()])
        #expect(assembler.assemblies.count == 1)
        
        try assembler.assemble()
        #expect(assembler.assemblies.count == 3)
    }
    
    @Test("All Assemblies Present")
    func allRequiredAssembliesPresentSucceeds() {
        let assemblies: [Assembly] = [
            MockAssembly(),
            NetworkingAssembly(),
            FeatureAssembly()
        ]
        
        #expect(throws: Never.self) {
            try Assembler(
                container: MockContainer(),
                assemblies: assemblies
            )
        }
        
        #expect(throws: Never.self) {
            let assembler = Assembler(container: MockContainer())
            try assembler.add(assemblies: assemblies).assemble()
        }
    }
    
    @Test("Order Does Not Matter")
    func assemblyOrderDoesNotMatter() {
        #expect(throws: Never.self) {
            try Assembler(
                container: MockContainer(),
                assemblies: [FeatureAssembly(), NetworkingAssembly(), MockAssembly()]
            )
        }
    }
    
    @Test("No Required Dependencies is OK")
    func assemblyWithNoDependenciesAlwaysValid() {
        #expect(throws: Never.self) {
            try Assembler(container: MockContainer(), assemblies: [MockAssembly()])
        }
    }
    
    @Test("Multiple Assemblies with Shared Dependencies")
    func multipleAssembliesWithSharedDependencies() {
        let container = MockContainer()
        #expect(throws: Never.self) {
            try Assembler(
                container: container,
                assemblies: [MockAssembly(), FeatureAssembly(), NetworkingAssembly(), AnalyticsAssembly()]
            )
        }
    }
    
    @Test("Duplicated Required Assemblies")
    func duplicateAssembliesAreHandled() {
        let container = MockContainer()
        #expect(throws: Never.self) {
            try Assembler(
                container: container,
                assemblies: [MockAssembly(), MockAssembly(), NetworkingAssembly(), FeatureAssembly()]
            )
        }
    }
    
    // MARK: Chaining Tests
    
    @Test("Add Single Assembly Chaining")
    func addSingleAssemblyChaining() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.add(assembly: assembly)
            .assemble()
        
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
    }
    
    @Test("Add Multiple Assemblies Chaining")
    func addMultipleAssembliesChaining() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.add(assemblies: [assembly1, assembly2])
            .assemble()
        
        #expect(assembly1.preassembleCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.postAssembleCalled)
        #expect(assembly2.preassembleCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembly2.postAssembleCalled)
    }
    
    @Test("IsAssembled Updates Correctly")
    func isAssembledFlagDoesNotUpdateWithNoAssemblies() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [])
        
        #expect(!assembler.isAssembled)
        try assembler.assemble()
        #expect(!assembler.isAssembled)
    }
    
    @Test("IsAssembled Updates on Init With Assemblies")
    func isAssembledFlagUpdatesUpdatesOnInit() throws {
        let container = MockContainer()
        let assembler = try Assembler(
            container: container,
            assemblies: [MockAssembly()]
        )
        
        #expect(assembler.isAssembled)
    }
    
    @Test("IsAssembled Is False After Adding an Assembly")
    func isAssembledFlagUpdatesDuringAdditionOfAssemblies() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [])
        
        #expect(!assembler.isAssembled)
        assembler.add(assembly: MockAssembly())
        #expect(!assembler.isAssembled)
    }
    
    @Test("Assemble Chaining Returns Self")
    func assembleChainingReturnsSelf() throws {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        let returned = try assembler.assemble()
        #expect(returned === assembler)
    }
    
    @Test("Assemble Twice Throws AlreadyAssembled")
    func assembleTwiceThrowsAlreadyAssembled() throws {
        let assembler = try Assembler(container: MockContainer(), assemblies: [MockAssembly()])
        
        #expect(throws: Assembler.Error.alreadyAssembled) {
            try assembler.assemble() // second call
        }
    }
    
    @Test("Add and Assemble Chaining Sequence")
    func addAndAssembleChainingSequence() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.add(assembly: assembly1)
            .add(assemblies: [assembly2])
            .assemble()
        
        #expect(assembly1.preassembleCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembler.isAssembled)
    }
    
    @Test("Assemble With No Assemblies Returns Self")
    func assembleWithNoAssembliesReturnsSelf() throws {
        let assembler = Assembler(container: MockContainer())
        let returned = try assembler.assemble()
        #expect(returned === assembler)
    }
    
    @Test("Assemblies Preloaded, Assembled, Loaded Called")
    func assembliesPreloadedAssembledAndLoadedAreCalled() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.add(assembly: assembly).assemble()
        
        #expect(assembly.preassembleCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.postAssembleCalled)
    }
    
    @Test("Multiple Assemblies Pre/Post Assemble Sequence")
    func multipleAssembliesPrePostSequence() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        
        var sequence: [String] = []
        assembly1.whenPreassemble = { sequence.append("pre1") }
        assembly1.whenAssemble = { sequence.append("assemble1") }
        assembly1.whenPostAssemble = { sequence.append("post1") }
        
        assembly2.whenPreassemble = { sequence.append("pre2") }
        assembly2.whenAssemble = { sequence.append("assemble2") }
        assembly2.whenPostAssemble = { sequence.append("post2") }
        
        let assembler = Assembler(container: container)
        try assembler.add(assemblies: [assembly1, assembly2]).assemble()
        
        #expect(sequence == [
            "pre1", "pre2", "assemble1", "assemble2", "post1", "post2"
        ])
    }
    
    @Test("No duplicate assemblies after validation and auto-init")
    func noDuplicateAssemblies() throws {
        let container = MockContainer()
        
        // Assemblies with shared dependencies
        let assembler = try Assembler(
            container: container,
            assemblies: [BranchA(), BranchB(), BranchC()],
            initializeMissingAssemblies: true
        )
        
        // Count occurrences of each assembly type
        var typeCounts: [String: Int] = [:]
        for assembly in assembler.assemblies {
            let name = String(describing: type(of: assembly))
            typeCounts[name, default: 0] += 1
        }
        
        // Assert each type occurs only once
        for (name, count) in typeCounts {
            #expect(count == 1, "Assembly \(name) occurs \(count) times, expected 1")
        }
    }
    
    @Test("Transitive dependencies are automatically initialized")
    func transitiveDependenciesAutoInit() throws {
        let container = MockContainer()
        let assembler = try Assembler(
            container: container,
            assemblies: [AAssembly()],
            initializeMissingAssemblies: true
        )
        
        let types = assembler.assemblies.map { type(of: $0) }
        
        #expect(types.contains(where: { $0 == AAssembly.self }))
        #expect(types.contains(where: { $0 == BAssembly.self }))
        #expect(types.contains(where: { $0 == CAssembly.self }))
    }
    
    @Test("Missing dependencies throw when auto-init is disabled")
    func missingDependenciesThrow() throws {
        let container = MockContainer()
        let assembler = Assembler(
            container: container,
            initializeMissingAssemblies: false
        )
        
        #expect(throws: Assembler.Error.missingRequiredAssemblies(["BAssembly", "CAssembly"])) {
            try assembler.add(assembly: AAssembly()).assemble()
        }
    }
    
    @Test("Circular dependencies throw circularDependency error")
    func circularDependenciesThrow() throws {
        let container = MockContainer()
        let assembler = Assembler(
            container: container,
            initializeMissingAssemblies: true
        )
        
        #expect(throws: Assembler.Error.circularDependency(["CircularA", "CircularB", "CircularA"])) {
            try assembler.add(assembly: CircularA()).assemble()
        }
    }
    
    @Test("Already assembled throws error")
    func alreadyAssembledThrows() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [CAssembly()])
        
        #expect(throws: Assembler.Error.alreadyAssembled) {
            try assembler.assemble()
        }
    }
    
    // MARK: - Circular dependency tests
    
    @Test("Self-cycle dependency throws circularDependency error")
    func selfCycleDependencyThrows() throws {
        let container = MockContainer()
        let assembler = Assembler(container: container, initializeMissingAssemblies: true)
        
        #expect(throws: Assembler.Error.circularDependency(["SelfCycle", "SelfCycle"])) {
            try assembler.add(assembly: SelfCycle()).assemble()
        }
    }
    
    @Test("Nested circular dependency")
    func nestedCircularDependencyThrows() throws {
        struct X: Assembly {
            static var requiredAssemblies: [Assembly.Type] { [Y.self] }
            func assemble(container: Container) throws {}
        }
        
        struct Y: Assembly {
            static var requiredAssemblies: [Assembly.Type] { [Z.self] }
            func assemble(container: Container) throws {}
        }
        
        struct Z: Assembly {
            static var requiredAssemblies: [Assembly.Type] { [X.self] }
            func assemble(container: Container) throws {}
        }
        
        let container = MockContainer()
        let assembler = Assembler(container: container, initializeMissingAssemblies: true)
        
        #expect(throws: Assembler.Error.circularDependency(["X", "Y", "Z", "X"])) {
            try assembler.add(assembly: X()).assemble()
        }
    }
    
    // MARK: - Transitive dependencies
    
    @Test("Deep chain auto-init")
    func deepChainAutoInit() throws {
        let container = MockContainer()
        let assembler = try Assembler(
            container: container,
            assemblies: [DAssembly()],
            initializeMissingAssemblies: true
        )
        let types = assembler.assemblies.map { type(of: $0) }
        #expect(types.contains(where: { $0 == DAssembly.self }))
        #expect(types.contains(where: { $0 == EAssembly.self }))
    }
    
    @Test("Multiple branches auto-init only once")
    func multipleBranchesAutoInit() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [BranchA()], initializeMissingAssemblies: true)
        let types = assembler.assemblies.map { type(of: $0) }
        
        #expect(types.contains(where: { $0 == BranchA.self }))
        #expect(types.contains(where: { $0 == BranchB.self }))
        #expect(types.contains(where: { $0 == BranchC.self }))
        #expect(types.contains(where: { $0 == BranchD.self }))
        
        // BranchD should only appear once
        let countD = types.filter { $0 == BranchD.self }.count
        #expect(countD == 1)
    }
    
    // MARK: - Misc edge cases
    
    @Test("Empty assembler does nothing")
    func emptyAssembler() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [], initializeMissingAssemblies: true)
        #expect(try assembler.assemble() === assembler)
    }
    
    @Test("Duplicate dependencies only added once")
    func duplicateDependenciesOnlyOnce() throws {
        let container = MockContainer()
        let assembler = try Assembler(
            container: container,
            assemblies: [BranchB(), BranchD()],
            initializeMissingAssemblies: true
        )
        try assembler.add(assemblies: [BranchC()]).assemble()
        
        let types = assembler.assemblies.map { type(of: $0) }
        let countD = types.filter { $0 == BranchD.self }.count
        #expect(countD == 1)
    }
    
    @Test("Assemble twice throws alreadyAssembled")
    func assembleTwiceThrows() throws {
        let container = MockContainer()
        let assembler = try Assembler(container: container, assemblies: [MockAssembly()])
        #expect(throws: Assembler.Error.alreadyAssembled) { try assembler.assemble() }
    }
    
    @Test("Assembly failure wraps underlying error")
    func assemblyFailureIsThrown() throws {
        struct FailingAssembly: Assembly {
            init() {}
            static var requiredAssemblies: [Assembly.Type] { [] }
            
            func preassemble() throws {
                throw MockError()
            }
            
            func assemble(container: Container) throws {}
            func postAssemble(resolver: Resolver) throws {}
        }
        
        let container = MockContainer()
        
        #expect(throws: Assembler.Error.assemblyFailure(MockError())) {
            try Assembler(container: container, assemblies: [FailingAssembly()])
        }
    }
    
    // MARK: - Add and Assemble Chaining Tests
    
    @Test("Add Assembly Returns Self")
    func addAssemblyReturnsSelf() {
        let assembler = Assembler(container: MockContainer())
        let returned = assembler.add(assembly: MockAssembly())
        
        #expect(returned === assembler)
    }
    
    @Test("Add Assemblies Returns Self")
    func addAssembliesReturnsSelf() {
        let assembler = Assembler(container: MockContainer())
        let returned = assembler.add(assemblies: [MockAssembly()])
        
        #expect(returned === assembler)
    }
    
    @Test("Assemble Returns Self For Chaining")
    func assembleReturnsSelf() throws {
        let assembler = Assembler(container: MockContainer())
        let returned = try assembler.assemble()
        
        #expect(returned === assembler)
    }
    
    @Test("Multiple Adds Before Assemble")
    func multipleAddsBeforeAssemble() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembly3 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler
            .add(assembly: assembly1)
            .add(assembly: assembly2)
            .add(assemblies: [assembly3])
            .assemble()
        
        #expect(assembly1.preassembleCalled)
        #expect(assembly2.preassembleCalled)
        #expect(assembly3.preassembleCalled)
        #expect(assembler.isAssembled)
    }
    
    // MARK: - Container Integration Tests
    
    @Test("Assembler Container Reference")
    func assemblerContainerReference() {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(assembler.container === container)
    }
    
    @Test("Assembler Resolver Is Container")
    func assemblerResolverIsContainer() {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(assembler.resolver === container)
    }
    
    // MARK: - Initialization Tests
    
    @Test("Initialize With Auto Init True")
    func initWithAutoInitTrue() throws {
        let container = MockContainer()
        let assembler = Assembler(
            container: container,
            initializeMissingAssemblies: true
        )
        
        #expect(!assembler.isAssembled)
        try assembler.add(assembly: FeatureAssembly()).assemble()
        #expect(assembler.isAssembled)
    }
    
    @Test("Initialize With Auto Init False")
    func initWithAutoInitFalse() throws {
        let container = MockContainer()
        let assembler = Assembler(
            container: container,
            initializeMissingAssemblies: false
        )
        
        #expect(throws: Assembler.Error.missingRequiredAssemblies(["MockAssembly", "NetworkingAssembly"])) {
            try assembler.add(assembly: FeatureAssembly()).assemble()
        }
    }
    
    // MARK: - Assembly Array Tests
    
    @Test("Assemblies List Initially Empty")
    func assembliesListInitiallyEmpty() {
        let assembler = Assembler(container: MockContainer())
        
        #expect(assembler.assemblies.isEmpty)
    }
    
    @Test("Assemblies List Contains Added Assemblies")
    func assembliesListContainsAdded() {
        let assembler = Assembler(container: MockContainer())
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        
        assembler.add(assembly: assembly1)
        assembler.add(assembly: assembly2)
        
        #expect(assembler.assemblies.count == 2)
    }
    
    @Test("Assemblies List Contains Initial Assemblies")
    func assembliesListContainsInitial() throws {
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = try Assembler(
            container: MockContainer(),
            assemblies: [assembly1, assembly2]
        )
        
        #expect(assembler.assemblies.count == 2)
        #expect(assembler.isAssembled)
    }
    
    // MARK: - Assembly Failure Tests
    
    @Test("Preassemble Failure Throws")
    func preassembleFailureThrows() throws {
        struct PreassembleFailingAssembly: Assembly {
            func preassemble() throws {
                throw MockError()
            }
            
            func assemble(container: Container) throws {}
            func postAssemble(resolver: Resolver) throws {}
        }
        
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(throws: Assembler.Error.assemblyFailure(MockError())) {
            try assembler.add(assembly: PreassembleFailingAssembly()).assemble()
        }
    }
    
    @Test("Assemble Failure Throws")
    func assembleFailureThrows() throws {
        struct AssembleFailingAssembly: Assembly {
            func assemble(container: Container) throws {
                throw MockError()
            }
        }
        
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(throws: Assembler.Error.assemblyFailure(MockError())) {
            try assembler.add(assembly: AssembleFailingAssembly()).assemble()
        }
    }
    
    @Test("PostAssemble Failure Throws")
    func postAssembleFailureThrows() throws {
        struct PostAssembleFailingAssembly: Assembly {
            func assemble(container: Container) throws {}
            
            func postAssemble(resolver: Resolver) throws {
                throw MockError()
            }
        }
        
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(throws: Assembler.Error.assemblyFailure(MockError())) {
            try assembler.add(assembly: PostAssembleFailingAssembly()).assemble()
        }
    }
    
    // MARK: - IsAssembled Flag Tests
    
    @Test("IsAssembled Initially False")
    func isAssembledInitiallyFalse() {
        let assembler = Assembler(container: MockContainer())
        
        #expect(!assembler.isAssembled)
    }
    
    @Test("IsAssembled True After Successful Assemble")
    func isAssembledTrueAfterAssemble() throws {
        let assembler = try Assembler(
            container: MockContainer(),
            assemblies: [MockAssembly()]
        )
        
        #expect(assembler.isAssembled)
    }
    
    @Test("IsAssembled False After Adding Assemblies")
    func isAssembledFalseAfterAddingAssemblies() throws {
        let assembler = try Assembler(
            container: MockContainer(),
            assemblies: [MockAssembly()]
        )
        
        #expect(assembler.isAssembled)
        assembler.add(assembly: NetworkingAssembly())
        #expect(!assembler.isAssembled)
    }
    
    // MARK: - Error Wrapping Tests
    
    @Test("Assembly Error Is Wrapped In AssemblyFailure")
    func assemblyErrorIsWrapped() throws {
        struct FailingAssembly: Assembly {
            func assemble(container: Container) throws {
                throw MockError()
            }
        }
        
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        do {
            try assembler.add(assembly: FailingAssembly()).assemble()
            #expect(Bool(false), "Should have thrown")
        } catch Assembler.Error.assemblyFailure(let error) {
            #expect(error is MockError)
        } catch {
            #expect(Bool(false), "Should have thrown Assembler.Error.assemblyFailure")
        }
    }
    
    // MARK: - Resolver Tests
    
    @Test("Resolver Returns Container")
    func resolverReturnsContainer() {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(assembler.resolver === container)
    }
    
    // MARK: - Empty And Edge Cases
    
    @Test("Add Empty Assembly Array")
    func addEmptyAssemblyArray() throws {
        let assembler = Assembler(container: MockContainer())
        
        try assembler.add(assemblies: []).assemble()
        #expect(!assembler.isAssembled)
    }
    
    @Test("Multiple Assemble Calls On Fresh Assemblies")
    func multipleAssemblesOnFreshAssemblies() throws {
        let assembler = Assembler(container: MockContainer())
        let assembly1 = MockAssembly()
        
        try assembler.add(assembly: assembly1).assemble()
        #expect(assembler.isAssembled)
        #expect(assembly1.preassembleCalled)
        
        // Reset for next assembly
        let assembly2 = MockAssembly()
        assembler.add(assembly: assembly2)
        #expect(!assembler.isAssembled)
        
        try assembler.assemble()
        #expect(assembler.isAssembled)
        #expect(assembly2.preassembleCalled)
    }
}
