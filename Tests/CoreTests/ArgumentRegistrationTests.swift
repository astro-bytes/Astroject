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
        let registration = RegistrationWithArgument(
            factory: factory,
            isOverridable: true,
            argumentType: Int.self,
            instanceType: MockInstance.self
        )
        
        #expect(registration.isOverridable)
        #expect(registration.instances.isEmpty)
        #expect(registration.instanceType == MockInstance<Int>.self)
        #expect(registration.argumentType == Int.self)
        #expect(registration.factory == factory)
        #expect(registration.actions.isEmpty)
    }
    
    @Test("Sets New Instance")
    func setsNewInstance() {
        fatalError("Implement")
    }
    
    @Test("After Init Adds Action")
    func afterInitAddsAction() {
        fatalError("Implement")
    }
    
    @Test("Set Instance")
    func setInstance() {
        fatalError("Implement")
    }
    
    @Suite("Sync Resolution")
    struct SyncResolution {
        @Test("No Cached Instance")
        func noCachedInstance() throws {
            var calledSet = false
            var calledGet = false
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(
                whenSet: { calledSet = true },
                whenGet: { calledGet = true; return nil }
            )
            let registration = RegistrationWithArgument(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer(), argument: 1)
            
            #expect(calledGet)
            #expect(calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cached Instance")
        func cachedInstance() throws {
            var calledSet = false
            var calledGet = false
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(
                whenSet: { calledSet = true },
                whenGet: { calledGet = true; return 1 }
            )
            let registration = RegistrationWithArgument(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try registration.resolve(MockContainer(), argument: 1)
            
            #expect(calledGet)
            #expect(calledSet == false)
            #expect(calledFactory == false)
            #expect(calledAfterInit == false)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cache Unique Arguments")
        func cacheUniqueArguments() throws {
            fatalError("Implement")
        }
        
        @Test("Throws Underlying Error")
        func throwsUnderlyingError() {
            fatalError("Implement")
        }
        
        @Test("Throws Astroject Error")
        func throwsAstrojectError() {
            fatalError("Implement")
        }
        
        @Test("Throws After Init Error")
        func throwsAfterInitError() {
            fatalError("Implement")
        }
    }
    
    @Suite("Async Resolution")
    struct AsyncResolution {
        @Test("No Cached Instance")
        func noCachedInstance() async throws {
            var calledSet = false
            var calledGet = false
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(
                whenSet: { calledSet = true },
                whenGet: { calledGet = true; return nil }
            )
            let registration = RegistrationWithArgument(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer(), argument: 1)
            
            #expect(calledGet)
            #expect(calledSet)
            #expect(calledFactory)
            #expect(calledAfterInit)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cached Instance")
        func cachedInstance() async throws {
            var calledSet = false
            var calledGet = false
            var calledFactory = false
            var calledAfterInit = false
            let factory = Factory<Int, (Resolver, Int)>(.sync { _, _ in
                calledFactory = true
                return 1
            })
            let instance = MockInstance<Int>(
                whenSet: { calledSet = true },
                whenGet: { calledGet = true; return 1 }
            )
            let registration = RegistrationWithArgument(
                factory: factory,
                isOverridable: true,
                argument: 1,
                instance: instance
            ).afterInit { _, _ in
                calledAfterInit = true
            }
            
            let result = try await registration.resolve(MockContainer(), argument: 1)
            
            #expect(calledGet)
            #expect(calledSet == false)
            #expect(calledFactory == false)
            #expect(calledAfterInit == false)
            #expect(result == 1)
            #expect(registration.instances[1] != nil)
        }
        
        @Test("Cache Unique Arguments")
        func cacheUniqueArguments() async throws {
            fatalError("Implement")
        }
        
        @Test("Throws Underlying Error")
        func throwsUnderlyingError() async {
            fatalError("Implement")
        }
        
        @Test("Throws Astroject Error")
        func throwsAstrojectError() async {
            fatalError("Implement")
        }
        
        @Test("Throws After Init Error")
        func throwsAfterInitError() async {
            fatalError("Implement")
        }
    }
    
    @Suite("Equality")
    struct Equality {
        @Test("Happy Path")
        func happyPath() {
            fatalError("Implement")
        }
        
        @Test("Instance Type Differs")
        func whenInstanceTypeDiffers() {
            fatalError("Implement")
        }
        
        @Test("Instance Value Differs")
        func whenInstanceValueDiffers() {
            fatalError("Implement")
        }
        
        @Test("Argument Type Differs")
        func whenArgumentTypeDiffers() {
            fatalError("Implement")
        }
        
        @Test("isOverridable Differs")
        func whenIsOverridableDiffers() {
            fatalError("Implement")
        }
        
        @Test("Factory Differs")
        func whenFactoryDiffers() {
            fatalError("Implement")
        }
        
        @Test("Cached Instance Sets Differs")
        func whenCachedInstanceSetsDiffer() {
            fatalError("Implement")
        }
        
        @Test("Cached Instance Differs")
        func whenCachedInstanceDiffers() {
            // Comparing when one has cached instances and the other does not.
            fatalError("Implement")
        }
    }
    
    @Suite("Thread Safety")
    struct ThreadSafety {
        @Test("Concurrent Resolve with Same Argument")
        func concurrentResolveWithSameArgument() {
            fatalError("Implement")
        }
        
        @Test("Concurrent Resolve with Different Arguments")
        func concurrentResolveWithDifferentArgument() {
            fatalError("Implement")
        }
        
        @Test("Concurrent As")
        func concurrentAs() {
            fatalError("Implement")
        }
        
        @Test("Concurrent After Init")
        func concurrentAfterInit() {
            fatalError("Implement")
        }
        
        @Test("Stress Test")
        func stressTest() {
            // Run thousands of concurrent resolutions with random arguments to stress test race conditions.
            fatalError("Implement")
        }
    }
}
