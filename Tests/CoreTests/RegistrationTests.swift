//
//  RegistrationTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/27/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Registration Tests")
struct RegistrationTests {
    @Test("Initialization")
    func initialization() {
        let factory = Factory<Int, Resolver>(.sync { _ in 1 })
        let registration = Registration(
            factory: factory,
            isOverridable: true,
            instanceType: MockInstance.self
        )
        
        #expect(registration.isOverridable)
        #expect(type(of: registration.instance) == MockInstance<Int>.self)
        #expect(registration.actions.isEmpty)
        #expect(registration.factory == factory)
    }
    
    @Test("Sets New Instance")
    func setsNewInstance() {
        let factory = Factory<Int, Resolver>(.sync { _ in 1 })
        let registration = Registration(
            factory: factory,
            isOverridable: true,
            instanceType: Singleton.self
        ).as(MockInstance.self)
        
        #expect(type(of: registration.instance) == MockInstance<Int>.self)
    }
    
    @Test("After Init Adds Action")
    func afterInitAddsAction() {
        let factory = Factory<Int, Resolver>(.sync { _ in 1 })
        let registration = Registration(
            factory: factory,
            isOverridable: true,
            instanceType: MockInstance.self
        ).afterInit { _, _ in }
        #expect(registration.actions.count == 1)
        
        registration.afterInit { _, _ in }
        #expect(registration.actions.count == 2)
    }
    
    @Suite("Sync Resolution")
    struct SyncResolution {
        @Test("No Cached Instance")
        func noCachedInstance() throws {
            var calledFactory = false
            var calledAfterInit = false
            let instance = MockInstance<Int>()
            let factory = Factory<Int, Resolver>(.sync { _ in
                calledFactory = true
                return 1
            })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer())
            
            #expect(instance.calledGet)
            #expect(instance.calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
        }
        
        @Test("Cached Instance")
        func cachedInstance() throws {
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, Resolver>(.sync { _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(whenGet: { 1 })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer())
            
            #expect(instance.calledGet)
            #expect(!instance.calledSet)
            #expect(!calledFactory)
            #expect(!calledAfterInit)
            #expect(result == 1)
        }
        
        @Test("Throws Underlying Error")
        func throwsUnderlyingError() {
            let factory = Factory<Int, Resolver>(.sync { _ in throw MockError() })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try registration.resolve(MockContainer())
            }
        }
        
        @Test("Throws Astroject Error")
        func throwsAstrojectError() {
            let factory = Factory<Int, Resolver>(.sync { _ in
                throw AstrojectError.invalidFactory
            })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(throws: AstrojectError.invalidFactory) {
                _ = try registration.resolve(MockContainer())
            }
        }
        
        @Test("Throws After Init Error")
        func throwsAfterInitError() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                throw MockError()
            }
            
            #expect(throws: AstrojectError.afterInit(MockError())) {
                _ = try registration.resolve(MockContainer())
            }
        }
    }
    
    @Suite("Async Resolution")
    struct AsyncResolution {
        @Test("No Cached Instance")
        func noCachedInstance() async throws {
            var calledFactory = false
            var calledAfterInit = false
            let instance = MockInstance<Int>()
            let factory = Factory<Int, Resolver>(.sync { _ in
                calledFactory = true
                return 1
            })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer())
            
            #expect(instance.calledGet)
            #expect(instance.calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
        }
        
        @Test("Cached Instance")
        func cachedInstance() async throws {
            var calledFactory = false
            var calledAfterInit = false
            let instance = MockInstance<Int>(whenGet: { 1 })
            let factory = Factory<Int, Resolver>(.sync { _ in
                calledFactory = true
                return 1
            })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer())
            
            #expect(instance.calledGet)
            #expect(!instance.calledSet)
            #expect(!calledFactory)
            #expect(!calledAfterInit)
            #expect(result == 1)
        }
        
        @Test("Throws Underlying Error")
        func throwsUnderlyingError() async {
            let factory = Factory<Int, Resolver>(.sync { _ in throw MockError() })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            await #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try await registration.resolve(MockContainer())
            }
        }
        
        @Test("Throws Astroject Error")
        func throwsAstrojectError() async {
            let factory = Factory<Int, Resolver>(.sync { _ in
                throw AstrojectError.invalidFactory
            })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            await #expect(throws: AstrojectError.invalidFactory) {
                _ = try await registration.resolve(MockContainer())
            }
        }
        
        @Test("Throws After Init Error")
        func throwsAfterInitError() async {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                throw MockError()
            }
            
            await #expect(throws: AstrojectError.afterInit(MockError())) {
                _ = try await registration.resolve(MockContainer())
            }
        }
    }
    
    @Suite("Equality")
    struct Equality {
        @Test("Happy Path")
        func whenHappyPath() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration1 = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(registration1.isEqual(to: registration2))
            #expect(registration1.isEqual(to: registration1))
            #expect(registration1 == registration2)
            #expect(registration1 == registration1)
        }
        
        @Test("IsOverridable Differs")
        func whenIsOverridableDiffers() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration1 = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = Registration(
                factory: factory,
                isOverridable: false,
                instanceType: MockInstance.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Factory Differs")
        func whenFactoryDiffers() {
            let factory1 = Factory<Int, Resolver>(.sync { _ in 1 })
            let factory2 = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration1 = Registration(
                factory: factory1,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = Registration(
                factory: factory2,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Instance Type Differs")
        func whenInstanceTypeDiffers() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let registration1 = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = Registration(
                factory: factory,
                isOverridable: true,
                instanceType: Singleton.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Instance Value Differs")
        func whenInstanceValueDiffers() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let instance1 = MockInstance<Int>(whenGet: { 1 })
            let instance2 = MockInstance<Int>(whenGet: { 2 })
            let registration1 = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance1
            )
            
            let registration2 = Registration(
                factory: factory,
                isOverridable: true,
                instance: instance2
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 == registration2)
        }
    }
}
