//
//  MockBehavior.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// Mock Behavior for testing
class MockBehavior: Behavior {
    var didRegisterCalled = false
    var registeredType: Any.Type?
    var registeredContainer: Container?
    var registeredRegistration: (any Registrable)?
    var registeredName: String?
    
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        didRegisterCalled = true
        registeredType = type
        registeredContainer = container
        registeredRegistration = registration
        registeredName = name
    }
    
    func reset() {
        self.didRegisterCalled = false
        self.registeredType = nil
        self.registeredContainer = nil
        self.registeredRegistration = nil
        self.registeredName = nil
    }
}
