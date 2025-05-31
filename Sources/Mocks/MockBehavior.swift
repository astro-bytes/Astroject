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
    var callsDidRegister = false
    var callsDidResolve = false
    
    var whenDidRegister: () -> Void = {}
    var whenDidResolve: () -> Void = {}
    
    func didResolve<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        callsDidResolve = true
        whenDidResolve()
    }
    
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        callsDidRegister = true
        whenDidRegister()
    }
}
