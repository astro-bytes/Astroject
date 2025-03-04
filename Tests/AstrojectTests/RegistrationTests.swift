//
//  RegistrationTests.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Astroject

@Suite("Registration")
struct RegistrationTests {
    @Test func registration() async throws {
        let container = Container()
        try await container.register(Int.self) { _ in 42 }
        let expected = Registration(container, factory: { _ in 42 }, isOverridable: true)
        let key = RegistrationKey(productType: Int.self)
        let registration = await container.registrations.getValue(for: key) as! Registration<Int>
        let result = await registration.isEqual(to: expected)
        #expect(result)
    }
    
    @Test func namedRegistration() async throws {
        let container = Container()
        try await container.register(Int.self, name: "42") { _ in 42 }
        let expected = Registration(container, factory: { _ in 42 }, isOverridable: true)
        let key = RegistrationKey(productType: Int.self, name: "42")
        let registration = await container.registrations.getValue(for: key) as! Registration<Int>
        let result = await registration.isEqual(to: expected)
        #expect(result)
    }
    
    @Test func noRegistrationFoundError() async throws {
        let container = Container()
        
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self)
        }
        
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self, name: "42")
        }
        
        
        try await container.register(Double.self) { _ in 42 }
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self, name: "42")
        }
        
        await container.clear()
        
        try await container.register(Double.self, name: "42") { _ in 42 }
        await #expect(throws: ResolutionError.noRegistrationFound) {
            try await container.resolve(Double.self)
        }
    }
    
    @Test func testRegistrationAlreadyExistsError() async throws {
        let container = Container()
        
        await #expect(throws: RegistrationError.alreadyRegistered) {
            try await container.register(Int.self, overridable: false) { _ in 42 }
            try await container.register(Int.self) { _ in 41 }
        }
        
        await #expect(throws: RegistrationError.alreadyRegistered) {
            try await container.register(String.self) { _ in "41" }
            try await container.register(String.self, overridable: false) { _ in "42" }
        }
    }
    
    @Test func clearRegistrations() async throws {
        let container = Container()
        try await container.register(Double.self) { _ in 42 }
        try await container.register(Int.self) { _ in 42 }
        let count = await container.registrations.count
        #expect(count == 2)
        
        await container.clear()
        
        let isEmpty = await container.registrations.isEmpty
        #expect(isEmpty)
    }
}
