//
//  ArgumentRegistrationTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/28/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Argument Registration Tests")
struct ArgumentRegistrationTests {
    @Test("Initializer")
    func initializer() {
        let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in 1 })
        let registration = ArgumentRegistration(
            factory: factory,
            isOverridable: true,
            instanceType: MockInstance.self
        )
        
        #expect(registration.isOverridable)
        #expect(registration.instances.isEmpty)
        #expect(registration.argumentType == Int.self)
        #expect(registration.factory == factory)
        #expect(registration.actions.isEmpty)
    }
    
    @Test("Sets New Instance")
    func whenUsingAs_setNewInstance() throws {
        let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in 1 })
        let registration = ArgumentRegistration(
            factory: factory,
            isOverridable: true,
            instanceType: Singleton.self
        ).as(MockInstance.self)
        
        #expect(registration.instances.isEmpty)
        
        _ = try registration.resolve(MockContainer(), argument: 1)
        
        #expect(type(of: registration.instances[1]!) == MockInstance<Int>.self)
    }
    
    @Test("After Init Adds Action")
    func whenUsingAfterInit_addAction() {
        let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in 1 })
        let registration = ArgumentRegistration(
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
        func whenNoCachedInstance_createNewCachedInstance() throws {
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer(), argument: 1)
            let instance = registration.instances[1]! as! MockInstance<Int>
            
            #expect(!instance.calledGet) // didn't exist
            #expect(instance.calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cached Instance")
        func whenCachedInstance_returnCache() throws {
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(whenGet: { 1 })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer(), argument: 1)
            
            #expect(instance.calledGet)
            #expect(!instance.calledSet)
            #expect(!calledFactory)
            #expect(!calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Caches Unique Arguments")
        func whenUniqueArgument_createNewCachedInstance() throws {
            var factoryCount = 0
            var afterInitCount = 0
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                factoryCount += 1
                return factoryCount
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                afterInitCount += 1
            }
            
            let result = try registration.resolve(MockContainer(), argument: 1)
            let instance1 = registration.instances[1]! as! MockInstance<Int>
            #expect(instance1.getCount == 0)
            #expect(instance1.setCount == 1)
            #expect(factoryCount == 1)
            #expect(afterInitCount == 1)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
            
            let result2 = try registration.resolve(MockContainer(), argument: 2)
            let instance2 = registration.instances[2]! as! MockInstance<Int>
            #expect(instance2.getCount == 0)
            #expect(instance2.setCount == 1)
            #expect(factoryCount == 2)
            #expect(afterInitCount == 2)
            #expect(result2 == 2)
            #expect(registration.instances[2] != nil)
        }
        
        @Test("Throws Underlying Error")
        func whenUnderlyingError_throwError() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in throw MockError() })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try registration.resolve(MockContainer(), argument: 1)
            }
        }
        
        @Test("Throws Astroject Error")
        func whenAstrojectError_throwError() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                throw AstrojectError.invalidFactory
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(throws: AstrojectError.invalidFactory) {
                _ = try registration.resolve(MockContainer(), argument: 1)
            }
        }
        
        @Test("Throws After Init Error")
        func whenAfterInitError_throwError() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                throw MockError()
            }
            
            #expect(throws: AstrojectError.afterInit(MockError())) {
                _ = try registration.resolve(MockContainer(), argument: 1)
            }
        }
    }
    
    @Suite("Async Resolution")
    struct AsyncResolution {
        @Test("No Cached Instance")
        func whenNoCachedInstance_createNewCachedInstance() async throws {
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.async { _, _ in
                calledFactory = true
                return 1
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer(), argument: 1)
            let instance = registration.instances[1]! as! MockInstance<Int>
            #expect(!instance.calledGet)
            #expect(instance.calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cached Instance")
        func whenCachedInstance_returnCache() async throws {
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.async { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(whenGet: { 1 })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer(), argument: 1)
            
            #expect(instance.calledGet)
            #expect(!instance.calledSet)
            #expect(!calledFactory)
            #expect(!calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Caches Unique Arguments")
        func whenUniqueArgument_createNewCachedInstance() async throws {
            var factoryCount = 0
            var afterInitCount = 0
            let factory = Factory<Int, (Resolver, Int)>(.async { _, _ in
                factoryCount += 1
                return factoryCount
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                afterInitCount += 1
            }
            
            let result = try await registration.resolve(MockContainer(), argument: 1)
            let instance1 = registration.instances[1]! as! MockInstance<Int>
            
            #expect(instance1.getCount == 0)
            #expect(instance1.setCount == 1)
            #expect(factoryCount == 1)
            #expect(afterInitCount == 1)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
            
            let result2 = try await registration.resolve(MockContainer(), argument: 2)
            let instance2 = registration.instances[2]! as! MockInstance<Int>
            
            #expect(instance2.getCount == 0)
            #expect(instance2.setCount == 1)
            #expect(factoryCount == 2)
            #expect(afterInitCount == 2)
            #expect(result2 == 2)
            #expect(registration.instances[2] != nil)
        }
        
        @Test("Throws Underlying Error")
        func whenUnderlyingError_throwError() async {
            let factory = Factory<Int, (Resolver, Int)>(.async { _, _ in throw MockError() })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            await #expect(throws: AstrojectError.underlyingError(MockError())) {
                _ = try await registration.resolve(MockContainer(), argument: 1)
            }
        }
        
        @Test("Throws Astroject Error")
        func whenAstrojectError_throwError() async {
            let factory = Factory<Int, (Resolver, Int)>(.async { _, _ in
                throw AstrojectError.invalidFactory
            })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            await #expect(throws: AstrojectError.invalidFactory) {
                _ = try await registration.resolve(MockContainer(), argument: 1)
            }
        }
        
        @Test("Throws After Init Error")
        func whenAfterInitError_throwError() async {
            let factory = Factory<Int, (Resolver, Int)>(.async { _ in 1 })
            let registration = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            ).afterInit { _, _ in
                throw MockError()
            }
            
            await #expect(throws: AstrojectError.afterInit(MockError())) {
                _ = try await registration.resolve(MockContainer(), argument: 1)
            }
        }
    }
    
    @Suite("Equality")
    struct Equality {
        @Test("Happy Path")
        func whenAllIsEqual() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration1 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(registration1.isEqual(to: registration2))
            #expect(registration1.isEqual(to: registration1))
            #expect(registration1 == registration2)
            #expect(registration1 == registration1)
        }
        
        @Test("isOverridable Differs")
        func whenIsOverridableDiffers() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration1 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory,
                isOverridable: false,
                instanceType: MockInstance.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Factory Differs")
        func whenFactoryDiffers() {
            let factory1 = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let factory2 = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration1 = ArgumentRegistration(
                factory: factory1,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory2,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Instance Type Differs")
        func whenInstanceTypeDiffers() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration1 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: Singleton.self
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
        }
        
        @Test("Instance Value Differs")
        func whenInstanceValueDiffers() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let instance1 = MockInstance<Int>(whenGet: { 1 })
            let instance2 = MockInstance<Int>(whenGet: { 2 })
            let registration1 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance1
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance2
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 == registration2)
        }
        
        @Test("Cached Instance Sets Differs")
        func whenCachedInstanceSetsDiffer() {
            let factory = Factory<Int, (Resolver, Int)>(.sync { _ in 1 })
            let registration1 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                instanceType: MockInstance.self
            )
            
            let registration2 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: MockInstance()
            )
            
            let registration3 = ArgumentRegistration(
                factory: factory,
                isOverridable: true,
                argument: 2,
                instance: MockInstance()
            )
            
            #expect(!registration1.isEqual(to: registration2))
            #expect(registration1 != registration2)
            #expect(!registration3.isEqual(to: registration2))
            #expect(registration3 != registration2)
        }
    }
}
