//
//  SyncContainerTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore
@testable import AstrojectSync

@Suite("Synchronous Container Test")
struct SyncContainerTests {
    @Test("Initialization")
    func initializeContainer() {
        let container = SyncContainer()
        
        #expect(container.behaviors.isEmpty)
        #expect(container.registrations.isEmpty)
    }
    
    @Test("Clear Container")
    func clearContainer() {}
    
    @Test("Add Behavior")
    func addBehavior() {}
    
    @Test("Concurrent Registrations")
    func whenConcurrentRegistrations_noCrashing() {}
    
    @Test("Concurrent Resolutions")
    func whenConcurrentResolutions_noCrashing() {}
    
    @Test("Is Registration Allowed Throws Error")
    func whenOverridingConflict_throwsError() {}
    
    @Test("New Context")
    func whenTopLevelResolution_newContextIsCreated() {}
    
    @Test("Increment Context Depth")
    func whenNestedResolution_contextDepthIsIncremented() {}
    
    @Suite("Without Arguments")
    struct WithoutArguments {
        @Test("Add Registration")
        func addRegistration() throws {
            let container = SyncContainer()
            let behavior = MockBehavior()
            let block: Factory<Int, Resolver>.Block = .sync { _ in 1 }
            let factory = Factory<Int, Resolver>(block)
            let key = RegistrationKey(factory: factory)
            let registration = Registration<Int>(
                factory: factory,
                isOverridable: true,
                instanceType: Graph.self
            )
            container.add(behavior)
            
            try container.register(Int.self, factory: factory)
            
            #expect(behavior.callsDidRegister)
            #expect(container.registrations[key] as! Registration == registration)
            #expect(container.isRegistered(Int.self))
        }
        
        @Test("Prevent Registration Overrides")
        func whenRegistrationOverridesDisabled_throwError() throws {
            let container = SyncContainer()
            let factory: Factory<Int, Resolver> = .init(.sync { _ in 1 })
            let key = RegistrationKey(factory: factory)
            
            try container.register(Int.self, isOverridable: false, factory: factory)
            
            #expect(throws: AstrojectError.alreadyRegistered(key: key)) {
                try container.register(Int.self) { 2 }
            }
        }
        
        @Test("Override Registration")
        func whenRegistrationOverridesEnabled_registerNewFactoryForKey() throws {
            let container = SyncContainer()
            let block = Factory<Int, Resolver>.Block.sync { _ in 1 }
            let factory1 = Factory<Int, Resolver>(block)
            let factory2 = Factory<Int, Resolver>(block)
            let key = RegistrationKey(factoryType: Factory<Int, Resolver>.SyncBlock.self, productType: Int.self)
            let registration1 = Registration(factory: factory1, isOverridable: true, instanceType: Graph.self)
            let registration2 = Registration(factory: factory2, isOverridable: true, instanceType: Graph.self)
            
            try container.register(Int.self, factory: factory1)
            try container.register(Int.self, factory: factory2)
            
            #expect(container.registrations[key] as! Registration != registration1)
            #expect(container.registrations[key] as! Registration == registration2)
        }
        
        @Test("Resolve")
        func resolve() {}
        
        @Test("Resolve Throws Not Registered Errors")
        func whenNotRegistered_ResolveThrows() {}
        
        @Test("Resolve Throws Underlying Errors")
        func whenFactoryError_ResolveThrows() {}
        
        @Test("Resolve Detects Circular Dependencies")
        func whenCircularDependencyExists_ResolveThrows() {}
    }
    
    @Suite("With Arguments")
    struct WithArguments {
        @Test("Add Registration")
        func addRegistration() throws {
            let container = SyncContainer()
            let behavior = MockBehavior()
            let block: Factory<Int, (Resolver, Int)>.Block = .sync { _, arg in arg }
            let factory = Factory<Int, (Resolver, Int)>(block)
            let key = RegistrationKey(factory: factory)
            let registration = ArgumentRegistration<Int, Int>(
                factory: factory,
                isOverridable: true,
                instanceType: Graph.self
            )
            container.add(behavior)
            
            try container.register(Int.self, argumentType: Int.self, factory: factory)
            
            #expect(behavior.callsDidRegister)
            #expect(container.registrations[key] as! ArgumentRegistration == registration)
            #expect(container.isRegistered(Int.self, and: Int.self))
        }
        
        @Test("Prevent Registration Overrides")
        func whenRegistrationOverridesDisabled_throwError() throws {
            let container = SyncContainer()
            let factory: Factory<Int, (Resolver, Int)> = .init(.sync { _, arg in arg })
            let key = RegistrationKey(factory: factory)
            
            try container.register(Int.self, argumentType: Int.self, factory: factory)
            
            #expect(throws: AstrojectError.alreadyRegistered(key: key)) {
                try container.register(Int.self, argumentType: Int.self, isOverridable: false) { arg in arg }
            }
        }
        
        @Test("Override Registration")
        func whenRegistrationOverridesEnabled_registerNewFactoryForKey() throws {
            let container = SyncContainer()
            let block = Factory<Int, (Resolver, Int)>.Block.sync { _, arg in arg }
            let factory1 = Factory<Int, (Resolver, Int)>(block)
            let factory2 = Factory<Int, (Resolver, Int)>(block)
            let key = RegistrationKey(factoryType: Factory<Int, Resolver>.SyncBlock.self, productType: Int.self, argumentType: Int.self)
            let registration1 = ArgumentRegistration(factory: factory1, isOverridable: true,  instanceType: Graph.self)
            let registration2 = ArgumentRegistration(factory: factory2, isOverridable: true, instanceType: Graph.self)
            
            try container.register(Int.self, argumentType: Int.self, factory: factory1)
            try container.register(Int.self, argumentType: Int.self, factory: factory2)
            
            #expect(container.registrations[key] as! ArgumentRegistration != registration1)
            #expect(container.registrations[key] as! ArgumentRegistration == registration2)
        }
        
        @Test("Resolve")
        func resolve() {}
        
        @Test("Resolve Throws Not Registered Errors")
        func whenNotRegistered_ResolveThrows() {}
        
        @Test("Resolve Throws Underlying Errors")
        func whenFactoryError_ResolveThrows() {}
        
        @Test("Resolve Detects Circular Dependencies")
        func whenCircularDependencyExists_ResolveThrows() {}
    }
}
