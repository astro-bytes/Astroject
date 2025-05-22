//
//  BehaviorTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Behavior")
struct BehaviorTests {
    
    @Test("Ensure didRegister is Called")
    func behaviorDidRegisterCalled() throws {
        let container = MockContainer()
        let behavior = MockBehavior()
        
        var didRegisterCalled = false
        behavior.whenDidRegister = {
            didRegisterCalled = true
        }
        
        container.add(behavior)
        
        try container.register(Int.self) { _ in 10 }
        
        #expect(didRegisterCalled)
    }
    
    @Test("Ensure didRegisterWithName is Called")
    func behaviorDidRegisterWithName() throws {
        let container = MockContainer()
        let behavior = MockBehavior()
        
        var didRegisterCalled = false
        behavior.whenDidRegister = {
            didRegisterCalled = true
        }
        
        container.add(behavior)
        
        try container.register(String.self, name: "testString") { _ in "Hello" }
        
        #expect(didRegisterCalled)
    }
    
    @Test("Testing Multiple Behaviors")
    func multipleBehaviors() throws {
        let container = MockContainer()
        let behavior1 = MockBehavior()
        let behavior2 = MockBehavior()
        
        var didRegister1 = false
        var didRegister2 = false
        
        behavior1.whenDidRegister = {
            didRegister1 = true
        }
        behavior2.whenDidRegister = {
            didRegister2 = true
        }
        
        container.add(behavior1)
        container.add(behavior2)
        
        try container.register(Double.self) { _ in 3.14 }
        
        #expect(didRegister1)
        #expect(didRegister2)
    }
    
    @Test("Behaviors with Multiple Registrations")
    func behaviorWithDifferentRegistrations() throws {
        let container = MockContainer()
        let behavior = MockBehavior()
        
        var didRegister = false
        behavior.whenDidRegister = {
            didRegister = true
        }
        
        container.add(behavior)
        
        try container.register(Int.self) { _ in 10 }
        try container.register(String.self, name: "testString") { _ in "Hello" }
        
        #expect(didRegister)
        
        // reset the behavior
        didRegister = false
        
        try container.register(Double.self) { _ in 4.0 }
        
        #expect(didRegister)
    }
}
