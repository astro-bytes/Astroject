//
//  MockAssembly.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import AstrojectCore

// Mock Assembly for testing
class MockAssembly: Assembly {
    var assembleCalled = false
    var loadedCalled = false
    
    func assemble(container: Container) {
        assembleCalled = true
    }
    
    func loaded(resolver: Resolver) {
        loadedCalled = true
    }
}
