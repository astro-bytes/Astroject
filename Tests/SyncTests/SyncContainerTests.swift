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

@Suite("Container Tests")
struct SyncContainerTests {
    @Test("Initialization")
    func initializeContainer() {
        let container = SyncContainer()
        
        #expect(container.behaviors.isEmpty)
        #expect(container.registrations.isEmpty)
    }
    
    @Test("Clear Container")
    func clearContainer() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 1 }
        try container.register(Int.self, argumentType: Int.self) { arg in arg }
        try container.register(Int.self, name: "test") { 2 }
        try container.register(Int.self, argumentType: Int.self, name: "test") { arg in arg }
        container.add(MockBehavior())
        
        container.clear()
        
        #expect(container.registrations.isEmpty)
        #expect(container.behaviors.isEmpty)
    }
    
    @Test("Add Behavior")
    func addBehavior() {
        let container = SyncContainer()
        let behavior1 = MockBehavior()
        let behavior2 = MockBehavior()
        
        container.add(behavior1)
        container.add(behavior2)
        
        #expect(container.behaviors as! [MockBehavior] == [behavior1, behavior2])
    }
    
    @Test("Concurrent Registrations")
    func whenConcurrentRegistrations_noCrashing() async throws {
        let container = SyncContainer()
        
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<500 {
                group.addTask {
                    #expect(throws: Never.self) {
                        try container.register(Int.self, name: index.description) { index }
                    }
                }
            }
        }
        
        for index in 0..<500 {
            let result = try await container.resolve(Int.self, name: index.description)
            #expect(result == index)
        }
    }
    
    @Test("Concurrent Resolutions")
    func whenConcurrentResolutions_noCrashing() async throws {
        let container = SyncContainer()
        for index in 0..<500 {
            try container.register(Int.self, name: index.description) { index }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<500 {
                group.addTask {
                    #expect(throws: Never.self) {
                        try container.resolve(productType: Int.self, name: index.description)
                    }
                }
            }
        }
    }
    
    @Test("Is Registration Allowed Throws Error")
    func whenOverridingConflict_throwsError() throws {
        let container = SyncContainer()
        let factory = Factory<Int, Resolver>(.sync { _ in 1 })
        let key = RegistrationKey(factory: factory)
        
        try container.register(Int.self, isOverridable: false, factory: factory)
        
        #expect(throws: AstrojectError.alreadyRegistered(key: key)) {
            try container.register(Int.self) { 2 }
        }
    }
    
    @Test("New Context")
    func whenTopLevelResolution_newContextIsCreated() throws {
        let container = SyncContainer()
        
        var wasCalled = false
        let freshContext = MockContext()
        freshContext.depth = 1
        
        // Override fresh and current to simulate top-level resolution
        MockContext.currentContext.depth = 0
        MockContext.currentContext.whenNext = {
            fatalError("next() should not be called for top-level resolution")
        }
        
        MockContext.whenFresh = { freshContext }
        
        MockContext.current.withValue(freshContext) {
            wasCalled = true
            return "resolved"
        }
        
        try container.manageContext(MockContext.currentContext) {}
        
        #expect(wasCalled)
    }
    
    @Test("Increment Context Depth")
    func whenNestedResolution_contextDepthIsIncremented() throws {
        let container = SyncContainer()
        let context = MockContext()
        context.depth = 1 // simulate nested resolution
        context.whenNext = { MockContext() }
        context.whenPush = { MockContext() }
        context.whenPop = { MockContext() }
        
        let key = RegistrationKey(factory: Factory<Int, Resolver>(.sync { _ in 1 }))
        context.graph.append(key)
        
        try container.manageContext(context) {}
        
        #expect(context.callsNext)
        #expect(!context.callsPush)
        #expect(!context.callsPop)
    }
    
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
        
        @Test("Is Registered")
        func whenRegistered_returnTrue() throws {
            let container = SyncContainer()
            
            try container.register(Int.self) { 1 }
            
            #expect(container.isRegistered(Int.self))
        }
        
        @Test("Is Not Registred")
        func whenNotRegistered_returnFalse() throws {
            let container = SyncContainer()
            
            #expect(!container.isRegistered(Int.self))
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
            let key = RegistrationKey(factory: factory1)
            let registration1 = Registration(factory: factory1, isOverridable: true, instanceType: Graph.self)
            let registration2 = Registration(factory: factory2, isOverridable: true, instanceType: Graph.self)
            
            try container.register(Int.self, factory: factory1)
            try container.register(Int.self, factory: factory2)
            
            #expect(container.registrations[key] as? Registration != registration1)
            #expect(container.registrations[key] as? Registration == registration2)
        }
        
        @Test("Resolve")
        func resolve() throws {
            let container = SyncContainer()
            let behavior = MockBehavior()
            container.add(behavior)
            try container.register(Int.self) { 1 }
            try container.register(String.self) { "1" }
            try container.register(Classes.ObjectD.self) { Classes.ObjectD() }
            try container.register(Classes.ObjectG.self) { Classes.ObjectG() }
            try container.register(Classes.ObjectF.self) { r in
                Classes.ObjectF(g: try r.resolve(Classes.ObjectG.self))
            }
            
            #expect(throws: Never.self) {
                _ = try container.resolve(Int.self)
            }
            #expect(throws: Never.self) {
                _ = try container.resolve(String.self)
            }
            #expect(throws: Never.self) {
                _ = try container.resolve(Classes.ObjectD.self)
            }
            #expect(throws: Never.self) {
                _ = try container.resolve(Classes.ObjectG.self)
            }
            #expect(throws: Never.self) {
                _ = try container.resolve(Classes.ObjectF.self)
            }
            #expect(behavior.callsDidResolve)
        }
        
        @Test("Resolve Throws Not Registered Errors")
        func whenNotRegistered_ResolveThrows() {
            let container = SyncContainer()
            let factory: Factory<Int, Resolver> = .init(.sync { _ in 0 })
            let key = RegistrationKey(factory: factory)
            
            #expect(throws: AstrojectError.noRegistrationFound(key: key)) {
                _ = try container.resolve(Int.self)
            }
        }
        
        @Test("Resolve Throws Underlying Errors")
        func whenFactoryError_ResolveThrows() throws {
            let container = SyncContainer()
            try container.register(Int.self) { throw MockError() }
            
            #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try container.resolve(Int.self)
            }
        }
        
        @Test("Resolve Detects Circular Dependencies")
        func whenCircularDependencyExists_ResolveThrows() throws {
            typealias A = CircularDependency.ObjectA
            typealias B = CircularDependency.ObjectB
            let container = SyncContainer()
            let aFactory: Factory<A, Resolver> = .init(.sync { r in A(b: try r.resolve(B.self)) })
            let bFactory: Factory<B, Resolver> = .init(.sync { r in B(a: try r.resolve(A.self)) })
            let aKey = RegistrationKey(factory: aFactory)
            let bKey = RegistrationKey(factory: bFactory)
            try container.register(A.self, factory: aFactory)
            try container.register(B.self, factory: bFactory)
            
            #expect(throws: AstrojectError.cyclicDependency(key: aKey, path: [aKey, bKey])) {
                _ = try container.resolve(A.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(key: bKey, path: [bKey, aKey])) {
                _ = try container.resolve(B.self)
            }
        }
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
        
        @Test("Is Registered")
        func whenRegistered_returnTrue() throws {
            let container = SyncContainer()
            
            try container.register(Int.self, argumentType: Int.self) { 1 }
            
            #expect(container.isRegistered(Int.self, and: Int.self))
        }
        
        @Test("Is Not Registred")
        func whenNotRegistered_returnFalse() throws {
            let container = SyncContainer()
            
            #expect(!container.isRegistered(Int.self, and: Int.self))
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
            let key = RegistrationKey(factory: factory1)
            let registration1 = ArgumentRegistration(factory: factory1, isOverridable: true,  instanceType: Graph.self)
            let registration2 = ArgumentRegistration(factory: factory2, isOverridable: true, instanceType: Graph.self)
            
            try container.register(Int.self, argumentType: Int.self, factory: factory1)
            try container.register(Int.self, argumentType: Int.self, factory: factory2)
            
            #expect(container.registrations[key] as? ArgumentRegistration != registration1)
            #expect(container.registrations[key] as? ArgumentRegistration == registration2)
        }
        
        @Test("Resolve")
        func resolve() throws {
            typealias E = Classes.ObjectE
            typealias F = Classes.ObjectF
            typealias G = Classes.ObjectG
            
            let container = SyncContainer()
            let behavior = MockBehavior()
            container.add(behavior)
            try container.register(Int.self, argumentType: Int.self) { arg in arg }
            try container.register(String.self, argumentType: String.self) { arg in arg }
            try container.register(F.self, argumentType: G.self) { g in F(g: g) }
            try container.register(E.self, argumentType: G.self) { r, g in
                E(f: try r.resolve(F.self, argument: g), g: g)
            }
            
            #expect(throws: Never.self) {
                let result = try container.resolve(Int.self, argument: 1)
                #expect(result == 1)
            }
            #expect(throws: Never.self) {
                let result = try container.resolve(String.self, argument: "1")
                #expect(result == "1")
            }
            #expect(throws: Never.self) {
                let g = G()
                let result = try container.resolve(E.self, argument: g)
                #expect(result.f.g === g)
                #expect(result.g === g)
            }
            #expect(throws: Never.self) {
                let g = G()
                let result = try container.resolve(F.self, argument: g)
                #expect(result.g === g)
            }
            #expect(behavior.callsDidResolve)
        }
        
        @Test("Resolve Throws Not Registered Errors")
        func whenNotRegistered_ResolveThrows() {
            let container = SyncContainer()
            let factory: Factory<Int, (Resolver, Int)> = .init(.sync { _, arg in arg })
            let key = RegistrationKey(factory: factory)
            
            #expect(throws: AstrojectError.noRegistrationFound(key: key)) {
                _ = try container.resolve(Int.self, argument: 1)
            }
        }
        
        @Test("Resolve Throws Underlying Errors")
        func whenFactoryError_ResolveThrows() throws {
            let container = SyncContainer()
            try container.register(Int.self, argumentType: Int.self) { _ in throw MockError() }
            
            #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try container.resolve(Int.self, argument: 1)
            }
        }
        
        @Test("Resolve Detects Circular Dependencies")
        func whenCircularDependencyExists_ResolveThrows() throws {
            typealias A = CircularDependency.ObjectA
            typealias B = CircularDependency.ObjectB
            let container = SyncContainer()
            let aFactory: Factory<A, (Resolver, Int)> = .init(.sync { r, arg in
                A(b: try r.resolve(B.self, argument: arg))
            })
            let bFactory: Factory<B, (Resolver, Int)> = .init(.sync { r, arg in
                B(a: try r.resolve(A.self, argument: arg))
            })
            let aKey = RegistrationKey(factory: aFactory)
            let bKey = RegistrationKey(factory: bFactory)
            try container.register(A.self, argumentType: Int.self, factory: aFactory)
            try container.register(B.self, argumentType: Int.self, factory: bFactory)
            
            #expect(throws: AstrojectError.cyclicDependency(key: aKey, path: [aKey, bKey])) {
                _ = try container.resolve(A.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(key: bKey, path: [bKey, aKey])) {
                _ = try container.resolve(B.self, argument: 1)
            }
        }
    }
}
