//
//  MockAssembly.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import AstrojectCore

// Mock Assembly for testing
class MockAssembly: Assembly {
    var loadedCalled = false
    var assembleCalled = false
    var whenAssemble: () throws -> Void = {}
    var whenLoaded: () throws -> Void = {}
    
    func assemble(container: Container) throws {
        assembleCalled = true
        try whenAssemble()
    }
    
    func loaded(resolver: Resolver) throws {
        loadedCalled = true
        try whenLoaded()
    }
}
