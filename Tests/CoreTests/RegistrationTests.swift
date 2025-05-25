//
//  RegistrationTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/24/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

// swiftlint:disable identifier_name
// swiftlint:disable type_name

@Suite("Registration")
struct RegistrationTests {

    typealias P = Classes.ObjectG // Assuming ObjectG is a class for '===' comparisons
    typealias R = Resolver

    // MARK: - Initialization Tests

    @Test("Registration initializes with provided factory, overridable status, and instance type")
    func testInitialization() throws {
        let factory: Factory<P, Resolver> = .init(.sync { _ in P() })
        let registration = Registration(
            factory: factory,
            isOverridable: true,
            instanceType: Transient.self
        )

        // It's hard to assert `factory` equality directly unless `Factory` is Equatable,
        // but we can assert the other properties.
        #expect(registration.isOverridable == true)
        #expect(type(of: registration.instance) == Transient<P>.self)
        // Ensure actions array is initially empty
        #expect(registration.actions.isEmpty)
    }

    // MARK: - Instance Strategy Assignment Tests

    @Test("as(instanceType:) sets instance strategy and clears previous cache behavior")
    func testAsSetsInstanceTypeAndClearsPreviousCacheBehavior() async throws { // Made async for potential factory calls
        var factoryCallCount = 0
        let factory: Factory<P, Resolver> = .init(.sync { _ in
            factoryCallCount += 1
            return P()
        })

        // Start with a Singleton strategy (something that caches)
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Singleton.self
        )

        // 1. Resolve with Singleton: should create once
        let product1_singleton = try await registration.resolve(MockContainer())
        #expect(factoryCallCount == 1)

        let product2_singleton = try await registration.resolve(MockContainer())
        #expect(product1_singleton === product2_singleton) // Still the same instance
        #expect(factoryCallCount == 1) // Factory not called again

        // 2. Change to Transient strategy
        registration.as(Transient.self)
        #expect(type(of: registration.instance) == Transient<P>.self) // Verify type change

        // 3. Resolve with new Transient strategy: should create a new instance
        let product3_transient = try await registration.resolve(MockContainer())
        #expect(factoryCallCount == 2) // Factory should be called again for the new strategy

        let product4_transient = try await registration.resolve(MockContainer())
        #expect(factoryCallCount == 3) // Factory should be called again
        #expect(product3_transient !== product4_transient) // Transient behavior confirmed

        // 4. Change back to Singleton strategy
        registration.as(Singleton<P>.self)
        #expect(type(of: registration.instance) == Singleton<P>.self)

        // 5. Resolve with re-applied Singleton: should create new instance once
        let product5_singleton = try await registration.resolve(MockContainer())
        #expect(factoryCallCount == 4) // Factory called for a new Singleton instance

        let product6_singleton = try await registration.resolve(MockContainer())
        #expect(factoryCallCount == 4) // Factory not called again
        #expect(product5_singleton === product6_singleton) // Singleton behavior confirmed
    }

    // MARK: - AfterInit Actions Tests

    @Test("afterInit adds action to actions array")
    func testAfterInitAddsAction() throws {
        let factory: Factory<P, Resolver> = .init(.sync { _ in P() })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self
        )

        var actionCalled = false
        registration.afterInit { _, _ in actionCalled = true }

        // Assuming `actions` is internal and accessible for testing.
        #expect(registration.actions.count == 1)
        // Manually execute the stored action to ensure it's correct
        try registration.actions.forEach { try $0(MockContainer(), P()) }
        #expect(actionCalled)
    }

    @Test("runActions executes all registered actions")
    func testRunActionsExecution() throws {
        let factory: Factory<P, Resolver> = .init(.sync { _ in P() })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self
        )

        var action1Called = false
        var action2Called = false

        registration.afterInit { _, _ in action1Called = true }
        registration.afterInit { _, _ in action2Called = true }

        let product = P()
        try registration.runActions(MockContainer(), product: product)

        #expect(action1Called == true)
        #expect(action2Called == true)
    }

    @Test("runActions throws underlying error if action fails")
    func testRunActionsThrowsError() throws {
        let factory: Factory<P, Resolver> = .init(.sync { _ in P() })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self
        )

        registration.afterInit { _, _ in throw MockError() }

        #expect(throws: AstrojectError.underlyingError(MockError())) {
            try registration.runActions(MockContainer(), product: P())
        }
    }

    // MARK: - Resolve Tests (Focus on `Registration`'s role in each strategy)

    @Test("resolve (sync) creates new instance for Transient default")
    func testSyncResolveTransientDefault() throws {
        var factoryCallCount = 0
        let factory: Factory<P, Resolver> = .init(.sync { _ in
            factoryCallCount += 1
            return P()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self // Explicitly Transient
        )

        let product1 = try registration.resolve(MockContainer())
        let product2 = try registration.resolve(MockContainer())

        #expect(product1 !== product2) // Transient: always new
        #expect(factoryCallCount == 2) // Each resolve should call factory
    }

    @Test("resolve (async) creates new instance for Transient default")
    func testAsyncResolveTransientDefault() async throws {
        var factoryCallCount = 0
        let factory: Factory<P, Resolver> = .init(.async { _ in
            factoryCallCount += 1
            return P()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self // Explicitly Transient
        )

        let product1 = try await registration.resolve(MockContainer())
        let product2 = try await registration.resolve(MockContainer())

        #expect(product1 !== product2) // Transient: always new
        #expect(factoryCallCount == 2) // Each resolve should call factory
    }

    @Test("resolve (sync) caches for Singleton default")
    func testSyncResolveSingletonDefault() throws {
        var factoryCallCount = 0
        let factory: Factory<P, Resolver> = .init(.sync { _ in
            factoryCallCount += 1
            return P()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Singleton.self // Explicitly Singleton
        )

        let product1 = try registration.resolve(MockContainer())
        let product2 = try registration.resolve(MockContainer())

        #expect(product1 === product2) // Same instance for Singleton
        #expect(factoryCallCount == 1) // Factory called only once
    }

    @Test("resolve (async) caches for Singleton default")
    func testAsyncResolveSingletonDefault() async throws {
        var factoryCallCount = 0
        let factory: Factory<P, Resolver> = .init(.async { _ in
            factoryCallCount += 1
            return P()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Singleton.self // Explicitly Singleton
        )

        let product1 = try await registration.resolve(MockContainer())
        let product2 = try await registration.resolve(MockContainer())

        #expect(product1 === product2)
        #expect(factoryCallCount == 1)
    }

    // Graph and Weak tests are omitted here as their behavior (per context, deallocation)
    // is best verified as part of the Container's overall resolution flow, where `Context.current`
    // is actively managed by `TaskLocal.withValue`.

    @Test("resolve (sync) throws UnderlyingError from factory")
    func testSyncResolveThrowsUnderlyingError() throws {
        let factory: Factory<P, Resolver> = .init(.sync { _ in
            throw MockError()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self
        )

        #expect(throws: AstrojectError.underlyingError(MockError())) {
            try registration.resolve(MockContainer())
        }
    }

    @Test("resolve (async) throws UnderlyingError from factory")
    func testAsyncResolveThrowsUnderlyingError() async throws {
        let factory: Factory<P, Resolver> = .init(.async { _ in
            throw MockError()
        })
        let registration = Registration(
            factory: factory,
            isOverridable: false,
            instanceType: Transient.self
        )

        await #expect(throws: AstrojectError.underlyingError(MockError())) {
            _ = try await registration.resolve(MockContainer())
        }
    }

    // MARK: - Equatable Conformance (Needs careful consideration)

    @Test("Registration Equatable behavior should be based on defining properties (Conceptual)")
    func testEquatableConceptualBehavior() throws {
        // The current `Equatable` implementation on `Registration` is problematic
        // because it compares resolved instances: `lhs.instance.get(for: context) == rhs.instance.get(for: context)`.
        // This means equality depends on whether a product has been resolved and
        // its current state within the instance strategy.
        // For `Transient`, `get` typically returns `nil`, so `nil == nil` means any two transient registrations
        // would be equal if no product has been resolved, even if their factories are different.
        // For `Singleton`/`Graph`/`Weak`, it depends on their resolution state and context.

        // If `Registration` needs to be Equatable, it should typically compare its defining characteristics:
        // - `isOverridable`
        // - `instanceType` (type equality)
        // - A way to compare the `factory` (which is hard for closures).
        // It should NOT involve `instance.get` or runtime state.

        // If your `RegistrationKey` uses `Registration` for its `Hashable`/`Equatable` implementation,
        // you MUST ensure `RegistrationKey` relies only on stable metadata (product type, argument type, name)
        // and not on the `Registration`'s current problematic `Equatable` implementation.

        // This test is kept as a conceptual placeholder to highlight the issue.
        // It will likely fail or be non-deterministic with the current `Equatable` implementation.
        // Consider removing `Equatable` from `Registration` if it's not strictly needed
        // for `RegistrationKey` (which should derive its hash/equality from other stable properties).

        let factoryA: Factory<P, Resolver> = .init(.sync { _ in P(int: 1) })
        let factoryB: Factory<P, Resolver> = .init(.sync { _ in P(int: 2) }) // Different logic

        let reg1 = Registration(factory: factoryA, isOverridable: false, instanceType: Transient.self)
        let reg2 = Registration(factory: factoryA, isOverridable: false, instanceType: Transient.self)
        // Different factory
        let reg3 = Registration(factory: factoryB, isOverridable: false, instanceType: Transient.self)
        // Different overridable
        let reg4 = Registration(factory: factoryA, isOverridable: true, instanceType: Transient.self)
        // Different instance type
        let reg5 = Registration(factory: factoryA, isOverridable: false, instanceType: Singleton.self)

        // With the current `Equatable` implementation based on `instance.get(for: context)`:
        // If run before resolution, `instance.get` is nil for Transient,
        // so reg1 == reg2 == reg3 == reg4 == reg5 would be true.
        // This is clearly incorrect for distinguishing registrations.

        // What you *conceptually* want for equality of distinct registrations:
        
        // Should be true if factories are considered logically equal
         #expect(reg1 == reg2)
        // Should be true if factories are distinct
         #expect(reg1 != reg3)
         #expect(reg1 != reg4)
         #expect(reg1 != reg5)
    }
}

// swiftlint:enable identifier_name
// swiftlint:enable type_name
