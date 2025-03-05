//
//  RegistrationTests.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Core

@Suite("Registration")
struct RegistrationTests {
    @Test func registration() throws {
        let container = Container()
        let factory = Factory<Int> { _ in 42 }
        try container.register(Int.self, factory: factory)
        let expected = Registration(factory: factory, isOverridable: true)
        let key = RegistrationKey(productType: Int.self)
        let registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func namedRegistration() throws {
        let container = Container()
        let factory = Factory { _ in 42 }
        try container.register(Int.self, name: "42", factory: factory)
        let expected = Registration(factory: factory, isOverridable: true)
        let key = RegistrationKey(productType: Int.self, name: "42")
        let registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func noRegistrationFoundError() async throws {
        let container = Container()
        
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self)
        }
        
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self, name: "42")
        }
        
        try container.register(Double.self) { _ in 42 }
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self, name: "42")
        }
        
        container.clear()
        
        try container.register(Double.self, name: "42") { _ in 42 }
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self)
        }
    }
    
    @Test func testRegistrationAlreadyExistsError() throws {
        let container = Container()
        
        #expect(throws: RegistrationError.alreadyRegistered) {
            try container.register(Int.self, isOverridable: false) { _ in 42 }
            try container.register(Int.self) { _ in 41 }
        }
        
        #expect(throws: RegistrationError.alreadyRegistered) {
            try container.register(String.self) { _ in "41" }
            try container.register(String.self, isOverridable: false) { _ in "42" }
        }
    }
    
    @Test func clearRegistrations() throws {
        let container = Container()
        try container.register(Double.self) { _ in 42 }
        
        #expect(container.registrations.count == 1)
        
        container.clear()
        
        #expect(container.registrations.isEmpty)
    }
}
