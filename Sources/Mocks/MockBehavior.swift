//
//  MockBehavior.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// Mock Behavior for testing
class MockBehavior: Behavior, Identifiable {
    let id: UUID = .init()
    
    var callsDidRegister = false
    var callsDidResolve = false
    
    var whenDidRegister: () -> Void = {}
    var whenDidResolve: () -> Void = {}
    
    func didResolve<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable,
        with name: String?
    ) {
        callsDidResolve = true
        whenDidResolve()
    }
    
    func didRegister<Product1, Product2>(
        type: Product1.Type,
        to container: any Container,
        as registration: any Registrable<Product2>,
        with name: String?
    ) {
        callsDidRegister = true
        whenDidRegister()
    }
}

extension MockBehavior: Equatable {
    static func == (lhs: MockBehavior, rhs: MockBehavior) -> Bool {
        lhs.id == rhs.id
    }
}
