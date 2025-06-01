//
//  AssemblerTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Foundation
import Testing
@testable import Mocks
@testable import AstrojectCore

/**
 ## TODO: Integration Tests (optional)
 
 - **Full assembly lifecycle**
 - Use mock `Assembly` implementations that record method calls.
 - Verify `preloaded`, `assemble`, and `loaded` called in correct order.
 - Verify dependencies registered in `assemble` are resolvable via `resolver`.
 
 - **Multiple assemblies with side effects**
 - Test multiple assemblies registering different services.
 - Verify all registrations exist in the container after assembly.
 
 - **Re-application**
 - Applying same assembly multiple times calls lifecycle methods each time.
 - Confirm no residual state causes failures.
 
 - **Performance**
 - Test `run(assemblies:)` completes within reasonable time for many assemblies.
 
 */
@Suite("Assembler Tests")
struct AssemblerTests {
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
        #expect(assembly1.preloadedCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.loadedCalled)
    }
    
    @Test("Init with Assembly")
    func initWithAssembly() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        
        let assembler = try Assembler(assembly: assembly, container: container)
        
        #expect(assembler.container === container)
        #expect(assembler.resolver === container)
        #expect(assembly.preloadedCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.loadedCalled)
    }
    
    @Test("Apply Single Assembly")
    func applySingleAssembly() throws {
        let assembly = MockAssembly()
        let assembler = Assembler(container: MockContainer())
        
        try assembler.apply(assembly: assembly)
        
        #expect(assembly.preloadedCalled)
        #expect(assembly.assembleCalled)
        #expect(assembly.loadedCalled)
    }
    
    @Test("Apply Multiple Assemblies")
    func applyMultipleAssemblies() throws {
        let container = MockContainer()
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        let assembler = Assembler(container: container)
        
        try assembler.apply(assemblies: [assembly1, assembly2])
        
        #expect(assembly1.preloadedCalled)
        #expect(assembly1.assembleCalled)
        #expect(assembly1.loadedCalled)
        #expect(assembly2.preloadedCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembly2.loadedCalled)
    }
    
    @Test("Runs Assembly in Correct Squence")
    func correctSequence() throws {
        let container = MockContainer()
        let assembly = MockAssembly()
        var sequence: [String] = []
        assembly.whenPreloaded = { sequence.append("preloaded") }
        assembly.whenAssemble = { sequence.append("assembled") }
        assembly.whenLoaded = { sequence.append("loaded") }
        
        let assembler = Assembler(container: container)
        try assembler.run(assemblies: [assembly])
        
        #expect(sequence == ["preloaded", "assembled", "loaded"])
    }
}
