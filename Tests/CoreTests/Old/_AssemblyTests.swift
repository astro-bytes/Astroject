////  AssemblyTests.swift
////  CoreTests
////
////  Created by Porter McGary on 3/4/25.
////
//
//import Testing
//@testable import Mocks
//@testable import AstrojectCore
//
//@Suite("Assembly")
//struct AssemblyTests {
//    @Test("Init")
//    func assemblerInitialization() {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        #expect(assembler.container as? MockContainer === container)
//    }
//    
//    @Test("Apply One Assembly")
//    func applySingleAssembly() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        let assembly = MockAssembly()
//        
//        try assembler.apply(assembly: assembly)
//        #expect(assembly.assembleCalled)
//        #expect(assembly.loadedCalled)
//    }
//    
//    @Test("Apply Multiple Assemblies")
//    func applyMultipleAssemblies() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        let assembly1 = MockAssembly()
//        let assembly2 = MockAssembly()
//        
//        try assembler.apply(assemblies: [assembly1, assembly2])
//        
//        #expect(assembly1.assembleCalled)
//        #expect(assembly1.loadedCalled)
//        #expect(assembly2.assembleCalled)
//        #expect(assembly2.loadedCalled)
//    }
//    
//    @Test("Assembly Initializers")
//    func assemblyInitializers() throws {
//        let container1 = MockContainer()
//        let assembly1 = MockAssembly()
//        let assembler1 = try Assembler(assembly: assembly1, container: container1)
//        #expect(assembler1.container as? MockContainer === container1)
//        #expect(assembly1.assembleCalled)
//        #expect(assembly1.loadedCalled)
//        
//        let container2 = MockContainer()
//        let assembly2 = MockAssembly()
//        let assembly3 = MockAssembly()
//        let assemblies = [assembly2, assembly3]
//        let assembler2 = try Assembler(assemblies: assemblies, container: container2)
//        #expect(assembler2.container as? MockContainer === container2)
//        #expect(assembly2.assembleCalled)
//        #expect(assembly2.loadedCalled)
//        #expect(assembly3.assembleCalled)
//        #expect(assembly3.loadedCalled)
//    }
//    
//    @Test("Assemblies are applied in order")
//    func assembliesAppliedInOrder() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        var order = 0
//        var order1 = 0
//        var order2 = 0
//        var order3 = 0
//        var order4 = 0
//        let assembly1 = MockAssembly()
//        let assembly2 = MockAssembly()
//        assembly1.whenAssemble = {
//            order += 1
//            order1 = order
//        }
//        assembly2.whenAssemble = {
//            order += 1
//            order2 = order
//        }
//        assembly1.whenLoaded = {
//            order += 1
//            order3 = order
//        }
//        assembly2.whenLoaded = {
//            order += 1
//            order4 = order
//        }
//        
//        try assembler.apply(assemblies: [assembly1, assembly2])
//        
//         #expect(order1 < order2)
//         #expect(order3 < order4)
//    }
//    
//    @Test("Empty Assemblies Array")
//    func emptyAssembliesArray() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        try assembler.apply(assemblies: []) // Should not throw
//    }
//    
//    @Test("Assembly Throwing Errors")
//    func assemblyThrowingErrors() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        let assembly = MockAssembly()
//        assembly.whenAssemble = {
//            throw MockError()
//        }
//        
//        #expect(throws: MockError.self) {
//            try assembler.apply(assembly: assembly)
//        }
//    }
//
//    @Test("Assembly Throwing Errors After Assembled")
//    func assemblyThrowingErrorsAfter() throws {
//        let container = MockContainer()
//        let assembler = Assembler(container: container)
//        let assembly = MockAssembly()
//        assembly.whenLoaded = {
//            throw MockError()
//        }
//        
//        #expect(throws: MockError.self) {
//            try assembler.apply(assembly: assembly)
//        }
//    }
//}
