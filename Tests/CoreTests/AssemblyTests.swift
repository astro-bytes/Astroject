//
//  AssemblyTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Testing
@testable import AstrojectCore

@Suite("Assembly")
struct AssemblyTests {
    @Test("Init")
    func assemblerInitialization() {
        let container = Container()
        let assembler = Assembler(container: container)
        #expect(assembler.container === container)
    }
    
    @Test("Apply One Assembly")
    func applySingleAssembly() {
        let container = Container()
        let assembler = Assembler(container: container)
        let assembly = MockAssembly()
        
        assembler.apply(assembly: assembly)
        
        #expect(assembly.assembleCalled)
        #expect(assembly.loadedCalled)
    }
    
    @Test("Apply Multiple Assemblies")
    func applyMultipleAssemblies() {
        let container = Container()
        let assembler = Assembler(container: container)
        let assembly1 = MockAssembly()
        let assembly2 = MockAssembly()
        
        assembler.apply(assemblies: [assembly1, assembly2])
        
        #expect(assembly1.assembleCalled)
        #expect(assembly1.loadedCalled)
        #expect(assembly2.assembleCalled)
        #expect(assembly2.loadedCalled)
    }
}
