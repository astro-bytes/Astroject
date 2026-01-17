//
//  MockAssembly.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import AstrojectCore

// Mock Assembly for testing
class MockAssembly: Assembly {
    var preassembleCalled = false
    var postAssembleCalled = false
    var assembleCalled = false
    
    var whenPreassemble: () throws -> Void = {}
    var whenAssemble: () throws -> Void = {}
    var whenPostAssemble: () throws -> Void = {}
    
    func preassemble() throws {
        preassembleCalled = true
        try whenPreassemble()
    }
    
    func assemble(container: Container) throws {
        assembleCalled = true
        try whenAssemble()
    }
    
    func postAssemble(resolver: any Resolver) throws {
        postAssembleCalled = true
        try whenPostAssemble()
    }
}
