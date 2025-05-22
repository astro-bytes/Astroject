//
//  MockAssembly.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import AstrojectCore

// Mock Assembly for testing
class MockAssembly: Assembly {
    var preloadedCalled = false
    var loadedCalled = false
    var assembleCalled = false
    
    var whenPreloaded: () throws -> Void = {}
    var whenAssemble: () throws -> Void = {}
    var whenLoaded: () throws -> Void = {}
    
    func preloaded() throws {
        preloadedCalled = true
    }
    
    func assemble(container: Container) throws {
        assembleCalled = true
        try whenAssemble()
    }
    
    func loaded(resolver: Resolver) throws {
        loadedCalled = true
        try whenLoaded()
    }
}
