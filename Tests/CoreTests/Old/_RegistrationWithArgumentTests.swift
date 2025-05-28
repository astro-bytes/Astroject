////
////   RegistrationWithArgumentTests.swift
////   Astroject
////
////   Created by Porter McGary on 5/24/25.
////
//
//import Testing
//@testable import Mocks
//@testable import AstrojectCore
//
//@Suite("RegistrationWithArgument")
//struct RegistrationWithArgumentTests {
//    
//    typealias P = Classes.ObjectG // Assuming ObjectG is a class, important for '==='
//    typealias R = Resolver
//    typealias A = Int
//    
//    // MARK: - Instance Strategy Assignment Tests
//    
//    @Test("as(instanceType:) sets instance strategy type and resets cached instances")
//    func testAsSetsInstanceTypeAndResetsCachedInstances() async throws { // Made async for async factories
//        var factoryCallCount = 0
//        let factory: Factory<P, (R, A)> = .init(.async { _, arg in // Use async factory
//            factoryCallCount += 1
//            return P(int: arg)
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Singleton.self // Start with a caching strategy
//        )
//        
//        // 1. Resolve some products to populate `instances` using the initial Singleton strategy
//        let product1_arg1 = try await registration.resolve(MockContainer(), argument: 1)
//        #expect(product1_arg1.int == 1)
//        #expect(factoryCallCount == 1)
//        
//        // Resolve again for same argument, should be cached (Singleton behavior)
//        let product2_arg1 = try await registration.resolve(MockContainer(), argument: 1)
//        #expect(product2_arg1.int == 1)
//        #expect(product1_arg1 === product2_arg1)
//        #expect(factoryCallCount == 1) // Still 1, instance reused
//        
//        // Resolve for a different argument (new Singleton instance for this arg)
//        let product1_arg2 = try await registration.resolve(MockContainer(), argument: 2)
//        #expect(product1_arg2.int == 2)
//        #expect(factoryCallCount == 2)
//        
//        // Ensure internal `instances` dictionary is populated for two arguments
//        #expect(registration.instances.count == 2)
//        
//        // 2. Change to Transient strategy - This should update `instanceType` and clear `instances`
//        registration.as(Transient.self)
//        
//        // Verify that the `instanceType` property has been updated
//        #expect(registration.instanceType is Transient<P>.Type) // This checks the type directly
//        
//        // Verify that the internal `instances` dictionary has been cleared
//        #expect(registration.instances.isEmpty) // Crucial for clearing old cached products
//        
//        // 3. Resolve with the new Transient strategy for argument 1 (new instance should be created)
//        let product3_arg1 = try await registration.resolve(MockContainer(), argument: 1)
//        #expect(product3_arg1.int == 1)
//        #expect(factoryCallCount == 3) // Factory called again for arg 1
//        
//        // Resolve again for same argument (should be new instance due to Transient)
//        let product4_arg1 = try await registration.resolve(MockContainer(), argument: 1)
//        #expect(product4_arg1.int == 1)
//        #expect(product3_arg1 !== product4_arg1) // Transient behavior confirmed
//        #expect(factoryCallCount == 4) // Factory called again
//        
//        // 4. Resolve with the new Transient strategy for argument 2 (new instance should be created)
//        let product3_arg2 = try await registration.resolve(MockContainer(), argument: 2)
//        #expect(product3_arg2.int == 2)
//        #expect(factoryCallCount == 5) // Factory called again for arg 2
//        
//        // 5. Change back to Singleton strategy
//        registration.as(Singleton.self)
//        #expect(registration.instanceType is Singleton<P>.Type)
//        #expect(registration.instances.isEmpty) // Should be empty after strategy change
//        
//        // 6. Resolve with re-applied Singleton: should create new instances once per arg
//        let product5_arg1 = try await registration.resolve(MockContainer(), argument: 1)
//        #expect(product5_arg1.int == 1)
//        #expect(factoryCallCount == 6) // Factory called for a new Singleton instance for arg 1
//        _ = try await registration.resolve(MockContainer(), argument: 1) // Should use cache
//        #expect(factoryCallCount == 6)
//        
//        let product5_arg2 = try await registration.resolve(MockContainer(), argument: 2)
//        #expect(product5_arg2.int == 2)
//        #expect(factoryCallCount == 7) // Factory called for a new Singleton instance for arg 2
//        _ = try await registration.resolve(MockContainer(), argument: 2) // Should use cache
//        #expect(factoryCallCount == 7)
//    }
//    
//    // MARK: - AfterInit Actions Tests
//    
//    @Test("afterInit adds action to actions array")
//    func testAfterInitAddsAction() throws {
//        let factory: Factory<P, (R, A)> = .init(.sync { _, _ in P() })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self // Use Transient as it doesn't cache
//        )
//        
//        var actionCalled = false
//        registration.afterInit { _, _ in actionCalled = true }
//        
//        // We can't directly check the internal `actions` array unless it's `internal var`.
//        // If `actions` is private, you'd test this via `resolve`.
//        // Assuming `actions` is `internal` for testing purposes as per current code structure.
//        #expect(registration.actions.count == 1)
//        // Manually run the action to verify it's stored correctly
//        try registration.actions.forEach { try $0(MockContainer(), P()) }
//        #expect(actionCalled)
//    }
//    
//    @Test("runActions executes all registered actions")
//    func testRunActionsExecution() throws {
//        let factory: Factory<P, (R, A)> = .init(.sync { _, _ in P() })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        
//        var action1Called = false
//        var action2Called = false
//        
//        registration.afterInit { _, _ in action1Called = true }
//        registration.afterInit { _, _ in action2Called = true }
//        
//        let product = P()
//        try registration.runActions(MockContainer(), product: product) // Directly test runActions
//        
//        #expect(action1Called == true)
//        #expect(action2Called == true)
//    }
//    
//    @Test("runActions throws underlying error if action fails")
//    func testRunActionsThrowsError() async throws {
//        let factory: Factory<P, (R, A)> = .init(.sync { _, _ in P() })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        
//        registration.afterInit { _, _ in throw MockError() }
//        
//        #expect(throws: AstrojectError.afterInit(MockError())) {
//            try registration.runActions(MockContainer(), product: P())
//        }
//    }
//    
//    // MARK: - Resolve Tests (Focus on `RegistrationWithArgument`'s role in each strategy)
//    
//    @Test("resolve (sync) creates new instance for Transient default")
//    func testSyncResolveTransientDefault() throws {
//        var factoryCallCount = 0
//        let factory: Factory<P, (R, A)> = .init(.sync { _, arg in
//            factoryCallCount += 1
//            return P(int: arg)
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self // Explicitly Transient
//        )
//        
//        let product1 = try registration.resolve(MockContainer(), argument: 1)
//        let product2 = try registration.resolve(MockContainer(), argument: 1)
//        let product3 = try registration.resolve(MockContainer(), argument: 2)
//        
//        #expect(product1.int == 1)
//        #expect(product2.int == 1)
//        #expect(product3.int == 2)
//        #expect(product1 !== product2) // Transient: always new
//        #expect(product1 !== product3)
//        #expect(product2 !== product3)
//        #expect(factoryCallCount == 3) // Each resolve should call factory
//    }
//    
//    @Test("resolve (async) creates new instance for Transient default")
//    func testAsyncResolveTransientDefault() async throws {
//        var factoryCallCount = 0
//        let factory: Factory<P, (R, A)> = .init(.async { _, arg in
//            factoryCallCount += 1
//            return P(int: arg)
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self // Explicitly Transient
//        )
//        
//        let product1 = try await registration.resolve(MockContainer(), argument: 1)
//        let product2 = try await registration.resolve(MockContainer(), argument: 1)
//        let product3 = try await registration.resolve(MockContainer(), argument: 2)
//        
//        #expect(product1.int == 1)
//        #expect(product2.int == 1)
//        #expect(product3.int == 2)
//        #expect(product1 !== product2) // Transient: always new
//        #expect(product1 !== product3)
//        #expect(product2 !== product3)
//        #expect(factoryCallCount == 3) // Each resolve should call factory
//    }
//    
//    @Test("resolve (sync) caches for Singleton default")
//    func testSyncResolveSingletonDefault() throws {
//        var factoryCallCount = 0
//        let factory: Factory<P, (R, A)> = .init(.sync { _, arg in
//            factoryCallCount += 1
//            return P(int: arg)
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Singleton.self // Explicitly Singleton
//        )
//        
//        let product1 = try registration.resolve(MockContainer(), argument: 1)
//        let product2 = try registration.resolve(MockContainer(), argument: 1)
//        let product3 = try registration.resolve(MockContainer(), argument: 2)
//        
//        #expect(product1.int == 1)
//        #expect(product2.int == 1)
//        #expect(product3.int == 2)
//        #expect(product1 === product2) // Same instance for same argument
//        #expect(product1 !== product3) // Different instance for different argument
//        #expect(factoryCallCount == 2) // Factory called once for arg 1, once for arg 2
//    }
//    
//    @Test("resolve (async) caches for Singleton default")
//    func testAsyncResolveSingletonDefault() async throws {
//        var factoryCallCount = 0
//        let factory: Factory<P, (R, A)> = .init(.async { _, arg in
//            factoryCallCount += 1
//            return P(int: arg)
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Singleton.self // Explicitly Singleton
//        )
//        
//        let product1 = try await registration.resolve(MockContainer(), argument: 1)
//        let product2 = try await registration.resolve(MockContainer(), argument: 1)
//        let product3 = try await registration.resolve(MockContainer(), argument: 2)
//        
//        #expect(product1.int == 1)
//        #expect(product2.int == 1)
//        #expect(product3.int == 2)
//        #expect(product1 === product2)
//        #expect(product1 !== product3)
//        #expect(factoryCallCount == 2)
//    }
//    
//    // Since `RegistrationWithArgument` doesn't manage `Context.current` with TaskLocals,
//    // tests for `Graph` and `Weak` scopes (which inherently rely on context identity or deallocation)
//    // are better placed in `AsyncContainerTests` where `Context.current` is properly managed
//    // via `TaskLocal.withValue`.
//    
//    // The @disabled test for argument-specific instance strategy is complex and might be
//    // better suited as an integration test on the container, or requires more sophisticated
//    // mocking of the `Instance` protocol if kept as a unit test here. For now, it's good to keep it disabled
//    // if `convert` method is not implemented or testable in isolation.
//    
//    @Test("resolve (sync) throws UnderlyingError from factory")
//    func testSyncResolveThrowsUnderlyingError() throws {
//        let factory: Factory<P, (R, A)> = .init(.sync { _, _ in
//            throw MockError()
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        
//        #expect(throws: AstrojectError.underlyingError(MockError())) {
//            try registration.resolve(MockContainer(), argument: 1)
//        }
//    }
//    
//    @Test("resolve (async) throws UnderlyingError from factory")
//    func testAsyncResolveThrowsUnderlyingError() async throws {
//        let factory: Factory<P, (R, A)> = .init(.async { _, _ in
//            throw MockError()
//        })
//        let registration = RegistrationWithArgument(
//            factory: factory,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        
//        await #expect(throws: AstrojectError.underlyingError(MockError())) {
//            _ = try await registration.resolve(MockContainer(), argument: 1)
//        }
//    }
//    
//    // MARK: - Equatable Conformance
//    
//    @Test("RegistrationWithArgument should be Equatable based on defining properties")
//    func testEquatable() throws {
//        // Factory blocks are not directly comparable for equality in Swift.
//        // `RegistrationKey` uses factory *type* and other metadata for hashing/equality.
//        // So, `RegistrationWithArgument` itself generally shouldn't be Equatable
//        // if the intention is for it to represent a unique registration in a dictionary key.
//        // If it MUST be Equatable, it needs a way to uniquely identify the factory,
//        // perhaps by hashing its memory address or requiring `Factory` to be `Equatable`.
//        // Given `RegistrationKey` handles unique identification, `RegistrationWithArgument`
//        // doesn't typically need `Equatable` for collection lookups.
//        // This test is conceptual and likely would fail with default Swift `==` on closures.
//        
//        // If your RegistrationWithArgument *does* implement Equatable,
//        // it should likely compare:
//        // - `isOverridable`
//        // - `argumentType`
//        // - `productType` (inferred from factory)
//        // - `instanceType`
//        // - A way to compare the factory, which is the trickiest part.
//        // It should NOT depend on `instances` dictionary content.
//        
//        // If RegistrationKey uses this, it means RegistrationKey's equality relies
//        // on the full Registration object, which is usually not what's desired for a *key*.
//        // A key should be simpler.
//        
//        // Assuming for the purpose of this test, if `Equatable` is implemented, it compares defining properties.
//        // If not, this test should be removed or changed to reflect actual `Equatable` purpose.
//        
//        let factoryA: Factory<P, (R, A)> = .init(.sync { _, _ in P() })
//        let factoryB: Factory<P, (R, A)> = .init(.sync { _, _ in P() })
//        
//        let reg1 = RegistrationWithArgument(
//            factory: factoryA,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        let reg2 = RegistrationWithArgument(
//            factory: factoryA,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        let reg3 = RegistrationWithArgument(
//            factory: factoryB,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        let reg4 = RegistrationWithArgument(
//            factory: factoryA,
//            isOverridable: true,
//            argumentType: Int.self,
//            instanceType: Transient.self
//        )
//        // Different instance type
//        let reg6 = RegistrationWithArgument(
//            factory: factoryA,
//            isOverridable: false,
//            argumentType: Int.self,
//            instanceType: Singleton.self
//        )
//        
//        // These expectations depend on how `Equatable` is implemented on `RegistrationWithArgument`.
//        // If `Equatable` simply compares memory addresses of closures, reg1 != reg2.
//        // If `Equatable` compares properties like isOverridable, argumentType, instanceType,
//        // and some derived identity for the factory, then:
//        
//        // Should be true if factories are deemed "equal" by some logical means
//        #expect(reg1 == reg2)
//        // Should be true if factoryB is distinct from factoryA
//        #expect(reg1 != reg3)
//        #expect(reg1 != reg4)
//        #expect(reg1 != reg6)
//        
//        // **Key takeaway:** `RegistrationWithArgument` itself probably doesn't need to be `Equatable`.
//        // `RegistrationKey` is the one that needs to be `Hashable` and `Equatable` to function as a dictionary key,
//        // and its `Hashable` / `Equatable` implementation should focus on the metadata that uniquely identifies
//        // a registration slot (product type, argument type, name, factory type).
//    }
//}
