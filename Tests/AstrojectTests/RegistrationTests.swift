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
    @Test func registration() throws {
        let container = Container()
        try container.register(Int.self) { _ in 42 }
        let expected = Registration(factory: .sync({_ in 42}), isOverridable: true)
        let key = RegistrationKey(productType: Int.self)
        let registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func namedRegistration() throws {
        let container = Container()
        try container.register(Int.self, name: "42") { _ in 42 }
        let expected = Registration(factory: .sync({_ in 42}), isOverridable: true)
        let key = RegistrationKey(productType: Int.self, name: "42")
        let registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func asyncRegistration() throws {
        let container = Container()
        try container.registerAsync(Int.self) { _ in 42 }
        let expected = Registration(factory: .async({_ in 42}), isOverridable: true)
        let key = RegistrationKey(productType: Int.self)
        let registration: Registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func namedAsyncRegistration() throws {
        let container = Container()
        try container.registerAsync(Int.self, name: "42") { _ in 42 }
        let expected = Registration(factory: .async({_ in 42}), isOverridable: true)
        let key = RegistrationKey(productType: Int.self, name: "42")
        let registration = container.registrations.getValue(for: key) as! Registration<Int>
        #expect(registration == expected)
    }
    
    @Test func noRegistrationFoundError() throws {
        let container = Container()
        
        #expect(throws: ResolutionError.noRegistrationFound) {
            try container.resolve(Double.self)
        }
        
        #expect(throws: ResolutionError.noRegistrationFound) {
            try container.resolve(Double.self, name: "42")
        }
        
        
        try container.register(Double.self) { _ in 42 }
        #expect(throws: ResolutionError.noRegistrationFound) {
            try container.resolve(Double.self, name: "42")
        }
        
        container.clear()
        
        try container.register(Double.self, name: "42") { _ in 42 }
        #expect(throws: ResolutionError.noRegistrationFound) {
            try container.resolve(Double.self)
        }
    }
    
    @Test func testRegistrationAlreadyExistsError() throws {
        let container = Container()
        
        #expect(throws: RegistrationError.alreadyRegistered) {
            try container.register(Int.self, overridable: false) { _ in 42 }
            try container.register(Int.self) { _ in 41 }
        }
        
        #expect(throws: RegistrationError.alreadyRegistered) {
            try container.register(String.self) { _ in "41" }
            try container.register(String.self, overridable: false) { _ in "42" }
        }
    }
    
    @Test func clearRegistrations() throws {
        let container = Container()
        try container.register(Double.self) { _ in 42 }
        try container.registerAsync(Int.self) { _ in 42 }
        
        #expect(container.registrations.count == 2)
        
        container.clear()
        
        #expect(container.registrations.isEmpty)
    }
}
