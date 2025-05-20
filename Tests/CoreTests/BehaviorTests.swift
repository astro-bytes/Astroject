//
//  BehaviorTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import AstrojectCore

@Suite("Behavior")
struct BehaviorTests {
    
    @Test("Ensure didRegister is Called")
    func behaviorDidRegisterCalled() throws {
        let container = Container()
        let behavior = MockBehavior()
        container.add(behavior)
        
        try container.register(Int.self) { _ in 10 }
        
        #expect(behavior.didRegisterCalled)
        #expect(behavior.registeredType == Int.self)
        #expect(behavior.registeredContainer === container)
        #expect(behavior.registeredRegistration != nil)
        #expect(behavior.registeredName == nil)
    }
    
    @Test("Ensure didRegisterWithName is Called")
    func behaviorDidRegisterWithName() throws {
        let container = Container()
        let behavior = MockBehavior()
        container.add(behavior)
        
        try container.register(String.self, name: "testString") { _ in "Hello" }
        
        #expect(behavior.didRegisterCalled)
        #expect(behavior.registeredType == String.self)
        #expect(behavior.registeredContainer === container)
        #expect(behavior.registeredRegistration != nil)
        #expect(behavior.registeredName == "testString")
    }
    
    @Test("Testing Multiple Behaviors")
    func multipleBehaviors() throws {
        let container = Container()
        let behavior1 = MockBehavior()
        let behavior2 = MockBehavior()
        container.add(behavior1)
        container.add(behavior2)
        
        try container.register(Double.self) { _ in 3.14 }
        
        #expect(behavior1.didRegisterCalled)
        #expect(behavior2.didRegisterCalled)
        #expect(behavior1.registeredType == Double.self)
        #expect(behavior2.registeredType == Double.self)
        #expect(behavior1.registeredContainer === container)
        #expect(behavior2.registeredContainer === container)
        #expect(behavior1.registeredRegistration != nil)
        #expect(behavior2.registeredRegistration != nil)
        #expect(behavior1.registeredName == nil)
        #expect(behavior2.registeredName == nil)
    }
    
    @Test("Behaviors with Multiple Registrations")
    func behaviorWithDifferentRegistrations() throws {
        let container = Container()
        let behavior = MockBehavior()
        container.add(behavior)
        
        try container.register(Int.self) { _ in 10 }
        try container.register(String.self, name: "testString") { _ in "Hello" }
        
        #expect(behavior.didRegisterCalled)
        #expect(behavior.registeredType == String.self)
        #expect(behavior.registeredName == "testString")
        
        // reset the behavior
        behavior.reset()
        
        try container.register(Double.self) { _ in 4.0 }
        
        #expect(behavior.didRegisterCalled)
        #expect(behavior.registeredType == Double.self)
        #expect(behavior.registeredName == nil)
    }
}
