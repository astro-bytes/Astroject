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
    var preLoadedCalled = false
    var postAssembleCalled = false
    var assembleCalled = false
    var loadedCalled = false
    
    var whenPreassemble: () throws -> Void = {}
    var whenPreLoaded: () throws -> Void = {}
    var whenAssemble: () throws -> Void = {}
    var whenPostAssemble: () throws -> Void = {}
    var whenLoaded: () throws -> Void = {}
    
    func preassemble() throws {
        preassembleCalled = true
        try whenPreassemble()
    }
    
    func preloaded() throws {
        preLoadedCalled = true
        try whenPreLoaded()
    }
    
    func assemble(container: Container) throws {
        assembleCalled = true
        try whenAssemble()
    }
    
    func postAssemble(resolver: any Resolver) throws {
        postAssembleCalled = true
        try whenPostAssemble()
    }
    
    func loaded(resolver: any Resolver) throws {
        loadedCalled = true
        try whenLoaded()
    }
    
    func reset() {
        preassembleCalled = false
        preLoadedCalled = false
        postAssembleCalled = false
        assembleCalled = false
        loadedCalled = false
    }
}
