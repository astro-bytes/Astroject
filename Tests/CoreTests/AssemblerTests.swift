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
    static let dependencies = requires([
        MockAssembly.self,
        NetworkingAssembly.self
    ])
    
    func requiredAssemblies() -> Set<ObjectIdentifier> { Self.dependencies }
    
    func assemble(container: Container) throws {}
}

struct AnalyticsAssembly: Assembly {
    static let dependencies = requires([MockAssembly.self])
    
    func requiredAssemblies() -> Set<ObjectIdentifier> { Self.dependencies }
    
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
        assembly.whenPreassemble = { sequence.append("preloaded") }
        assembly.whenAssemble = { sequence.append("assembled") }
        assembly.whenPostAssemble = { sequence.append("loaded") }
        
        let assembler = Assembler(container: container)
        try assembler.run(assemblies: [assembly])
        
        #expect(sequence == ["preloaded", "assembled", "loaded"])
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
    
    @Test("Missing Assemblies")
    func missingRequiredAssembliesThrows() throws {
        let container = MockContainer()
        let assembler = Assembler(container: container)
        
        #expect(throws: Assembler.Error.missingRequiredAssemblies) {
            try assembler.add(assemblies: [FeatureAssembly()]).assemble()
        }
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
    
    @Test("IsAssembled Updates Correctly")
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
        
        #expect(sequence == ["pre1","pre2","assemble1","assemble2","post1","post2"])
    }
}
