//
//  SyncContainerTests.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//
import Testing
import Foundation
@testable import AstrojectCore
@testable import Mocks
@testable import Sync

// swiftlint:disable identifier_name
// swiftlint:disable force_cast
// swiftlint:disable type_name
// swiftlint:disable nesting
// swiftlint:disable line_length

@Suite("Container")
struct SyncContainerTests {
    @Test("Validate isRegistered")
    func isRegistered() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 1 }
        try container.register(Int.self, name: "2") { 2 }
        try container.register(Int.self, name: "3", argument: String.self) { _,_ in 3 }
        try container.register(Int.self, argument: String.self) { _,_ in 4 }
        
        #expect(container.isRegistered(Int.self))
        #expect(container.isRegistered(Int.self, with: "2"))
        #expect(container.isRegistered(Int.self, with: "3", and: String.self))
        #expect(container.isRegistered(Int.self, and: String.self))
    }
    
    @Test("Add a Behavior")
    func addBehavior() throws {
        let container = SyncContainer()
        let behavior1 = MockBehavior()
        let behavior2 = MockBehavior()
        
        container.add(behavior1)
        container.add(behavior2)
        
        #expect(container.behaviors.count == 2)
        #expect((container.behaviors[0] as? MockBehavior) === behavior1)
        #expect((container.behaviors[1] as? MockBehavior) === behavior2)
    }
    
    @Test("Find a Registration")
    func findRegistration() throws {
        let container = SyncContainer()
        let factory = Factory { 42 }
        try container.register(Int.self, factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: nil)
        #expect(registration.factory == factory)
        
        #expect(throws: AstrojectError.noRegistrationFound(type: "\(Double.self)", name: nil)) {
            _ = try container.findRegistration(for: Double.self, with: nil)
        }
    }
    
    @Test("Find a Named Registration")
    func findNamedRegistration() throws {
        let container = SyncContainer()
        let factory = Factory { 42 }
        try container.register(Int.self, name: "test", factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: "test")
        #expect(registration.factory == factory)
        
        #expect(throws: AstrojectError.noRegistrationFound(type: "\(Int.self)", name: "wrongName")) {
            _ = try container.findRegistration(for: Int.self, with: "wrongName")
        }
    }
    
    @Test("Validate Overriding Registration is Allowed")
    func assertRegistrationAllowed() throws {
        let container = SyncContainer()
        let factory = Factory { 42 }
        
        try container.register(Int.self, factory: factory)
        try container.register(Int.self, factory: factory) // Should succeed, as it's overridable
        
        #expect(throws: AstrojectError.alreadyRegistered(type: "\(String.self)")) {
            try container.register(String.self, isOverridable: false) { "test" }
            try container.register(String.self) { "test2" }
        }
    }
    
    @Test("Clear all Registrations")
    func clearRegistrations() throws {
        let container = SyncContainer()
        try container.register(Double.self) { 42 }
        
        #expect(container.registrations.count == 1)
        
        container.clear()
        
        #expect(container.registrations.isEmpty)
    }
}

// MARK: Registration
extension SyncContainerTests {
    @Suite("Registration")
    struct RegistrationTests {
        @Test("Registration Happy Path")
        func registration() throws {
            let container = SyncContainer()
            let factory = Factory { 42 }
            try container.register(Int.self, factory: factory)
            let expected = Registration(factory: factory, isOverridable: true, instance: Transient())
            let key = RegistrationKey(productType: Int.self)
            let registration = container.registrations[key] as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test("Validate Named Registration")
        func namedRegistration() throws {
            let container = SyncContainer()
            let factory = Factory { 42 }
            try container.register(Int.self, name: "42", factory: factory)
            let expected = Registration(factory: factory, isOverridable: true, instance: Transient())
            let key = RegistrationKey(productType: Int.self, name: "42")
            let registration = container.registrations[key] as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test("Throw Already Registered Error")
        func registrationAlreadyExistsError() throws {
            let container = SyncContainer()
            
            #expect(throws: AstrojectError.alreadyRegistered(type: "\(Int.self)", name: nil)) {
                try container.register(Int.self, isOverridable: false) { _ in 42 }
                try container.register(Int.self) { _ in 41 }
            }
            
            #expect(throws: AstrojectError.alreadyRegistered(type: "\(String.self)", name: nil)) {
                try container.register(String.self) { _ in "41" }
                try container.register(String.self, isOverridable: false) { _ in "42" }
            }
        }
    }
}

// MARK: Resolution
extension SyncContainerTests {
    @Suite("Resolution")
    struct ResolutionTests {
        @Test("Resolve Happy Path")
        func resolution() throws {
            let container = SyncContainer()
            try container.register(Int.self) { _ in 42 }
            let resolvedValue: Int = try container.resolve(Int.self)
            #expect(resolvedValue == 42)
            
            let a = try container.resolve(Protocols.Animal.self)
        }
        
        @Test("Named Resolution Happy Path")
        func namedResolution() throws {
            let container = SyncContainer()
            try container.register(Int.self, name: "41") { _ in 41 }
            try container.register(Int.self, name: "42") { _ in 42 }
            let resolved41 = try container.resolve(Int.self, name: "41")
            let resolved42 = try container.resolve(Int.self, name: "42")
            #expect(resolved41 == 41)
            #expect(resolved42 == 42)
        }
        
        @Test("Argument Resolution Happy Path")
        func argumentResolution() throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            try container.register(G.self, argument: Int.self) { _, int in
                G(int: int)
            }
            
            let first = try container.resolve(G.self, argument: 1)
            let second = try container.resolve(G.self, argument: 2)
            let third = try container.resolve(G.self, argument: 1)
            
            #expect(first !== second)
            #expect(third.int == first.int)
        }
        
        @Test("Named Argument Resolution Happy Path")
        func namedArgumentResolution() throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            
            try container.register(G.self, name: "g", argument: Int.self) { _, int in
                .init(int: int)
            }
            
            let first = try container.resolve(productType: G.self, name: "g", argument: 1)
            let second = try container.resolve(productType: G.self, name: "g", argument: 2)
            let third = try container.resolve(productType: G.self, name: "g", argument: 1)
            
            #expect(first !== second)
            #expect(third.int == first.int)
        }
        
        @Test("Throw No Registration Error")
        func noRegistrationFoundError() throws {
            let container = SyncContainer()
            
            #expect(throws: AstrojectError.noRegistrationFound(type: "\(Double.self)", name: nil)) {
                try container.resolve(Double.self)
            }
            
            #expect(throws: AstrojectError.noRegistrationFound(type: "\(Double.self)", name: "42")) {
                try container.resolve(Double.self, name: "42")
            }
            
            #expect(throws: AstrojectError.noRegistrationFound(type: "\(Double.self)", name: "42")) {
                try container.resolve(Double.self, name: "42", argument: "1")
            }
            
            #expect(throws: AstrojectError.noRegistrationFound(type: "\(Double.self)", name: nil)) {
                try container.resolve(Double.self, argument: "1")
            }
        }
        
        @Test("Throw Resolution Error")
        func underlyingFactoryError() throws {
            let container = SyncContainer()
            try container.register(Int.self) { _ in throw MockError() }
            #expect(throws: AstrojectError.underlyingError(MockError())) {
                try container.resolve(Int.self)
            }
        }
    }
}

// MARK: Thread Safety
extension SyncContainerTests {
    @Suite("Thread Safety")
    struct ThreadSafetyTests {
        @Test("Register Concurrently")
        func concurrentRegistration() async throws {
            let container = SyncContainer()
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        let type = i % 3 // Cycle through 3 types
                        switch type {
                        case 0:
                            let result = try? container.register(Int.self, name: "int\(i)") { i }
                            #expect(result != nil)
                        case 1:
                            let result = try? container.register(String.self, name: "string\(i)") { "string\(i)" }
                            #expect(result != nil)
                        case 2:
                            let result = try? container.register(Double.self, name: "double\(i)") { Double(i) }
                            #expect(result != nil)
                        default:
                            break
                        }
                    }
                }
            }
            
            // Verify registrations
            for i in 0..<iterations {
                let type = i % 3
                switch type {
                case 0:
                    #expect(container.isRegistered(Int.self, with: "int\(i)"))
                case 1:
                    #expect(container.isRegistered(String.self, with: "string\(i)"))
                case 2:
                    #expect(container.isRegistered(Double.self, with: "double\(i)"))
                default:
                    break
                }
            }
        }
        
        @Test("Resolve Concurrently")
        func concurrentResolution() async throws {
            let container = SyncContainer()
            try container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        #expect(throws: Never.self) {
                            let result = try container.resolve(Int.self)
                            #expect(result == 42)
                        }
                    }
                }
            }
        }
        
        @Test("Concurrent Registration and Resolution")
        func concurrentRegistrationAndResolution() async throws {
            let container = SyncContainer()
            try container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        if i % 2 == 0 {
                            #expect(throws: Never.self) {
                                try container.register(String.self, name: "string\(i)") { "string\(i)" }
                            }
                        } else {
                            #expect(throws: Never.self) {
                                let result = try container.resolve(Int.self)
                                #expect(result == 42)
                            }
                        }
                    }
                }
            }
            
            // Verify registrations
            for i in 0..<iterations where i % 2 == 0 {
                #expect(container.isRegistered(String.self, with: "string\(i)"))
            }
        }
        
        @Test("Concurrent Behavior Registration")
        func concurrentBehaviorAddition() async throws {
            let container = SyncContainer()
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        let behavior = MockBehavior() // Create a mock behavior
                        container.add(behavior)
                    }
                }
            }
            
            #expect(container.behaviors.count == iterations)
        }
        
        @Test("Concurrent Clear")
        func concurrentClear() async throws {
            let container = SyncContainer()
            try container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        container.clear()
                    }
                }
            }
            
            #expect(container.registrations.isEmpty)
        }
        
        @Test("Concurrent Resolution with Different Types")
        func concurrentResolutionWithDifferentTypes() async throws {
            let container = SyncContainer()
            try container.register(Int.self) { 42 }
            try container.register(String.self) { "hello" }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        if i % 2 == 0 {
                            #expect(throws: Never.self) {
                                let result: Int = try container.resolve(Int.self)
                                #expect(result == 42)
                            }
                        } else {
                            #expect(throws: Never.self) {
                                let result: String = try container.resolve(String.self)
                                #expect(result == "hello")
                            }
                        }
                    }
                }
            }
        }
        
        @Test("Concurrent Registration with the Same Type & Different Names")
        func concurrentRegistrationOfSameTypeWithDifferentNames() async throws {
            let container = SyncContainer()
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        let result = try? container.register(Int.self, name: "name\(i)") { i }
                        #expect(result != nil)
                    }
                }
            }
            
            for i in 0..<iterations {
                #expect(container.isRegistered(Int.self, with: "name\(i)"))
            }
        }
        
        @Test("Mixed Concurrent Operations")
        func mixedConcurrentOperations() async throws {
            let container = SyncContainer()
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        // Concurrent registration of different types with unique names
                        let intResult = try? container.register(Int.self, name: "int\(i)") { i }
                        #expect(intResult != nil)
                        
                        let stringResult = try? container.register(String.self, name: "string\(i)") { "string\(i)" }
                        #expect(stringResult != nil)
                        
                        // Concurrent resolution of some of the registered types
                        if i % 5 == 0 { // Resolve less frequently than registering
                            let resolvedInt: Int? = try? container.resolve(Int.self, name: "int\(i)")
                            #expect(resolvedInt == i)
                        }
                        if i % 7 == 0 {
                            let resolvedString: String? = try? container.resolve(String.self, name: "string\(i)")
                            #expect(resolvedString == "string\(i)")
                        }
                    }
                }
            }
            
            // After all tasks complete, verify that all registrations are still present
            for i in 0..<iterations {
                #expect(container.isRegistered(Int.self, with: "int\(i)"))
                #expect(container.isRegistered(String.self, with: "string\(i)"))
            }
        }
        
        @Test("Concurrent Resolution with Shared Dependencies")
        func concurrentResolutionWithSharedDependencies() async throws {
            class SharedDependency {}
            
            class ObjectA {
                let shared: SharedDependency
                init(shared: SharedDependency) {
                    self.shared = shared
                }
            }
            
            class ObjectB {
                let shared: SharedDependency
                init(shared: SharedDependency) {
                    self.shared = shared
                }
            }
            
            let container = SyncContainer()
            // Register a shared dependency
            try container.register(SharedDependency.self) { SharedDependency() }
            
            // Register two types that depend on the shared dependency
            try container.register(ObjectA.self) { resolver in
                let shared = try resolver.resolve(SharedDependency.self)
                return ObjectA(shared: shared)
            }
            try container.register(ObjectB.self) { resolver in
                let shared = try resolver.resolve(SharedDependency.self)
                return ObjectB(shared: shared)
            }
            
            let iterations = 50
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        let a = try? container.resolve(ObjectA.self)
                        let b = try? container.resolve(ObjectB.self)
                        #expect(a != nil)
                        #expect(b != nil)
                    }
                }
            }
        }
    }
}

// MARK: Circular Dependency Tests
extension SyncContainerTests {
    @Suite("Circular Dependency")
    struct CircularDependencyTests {
        @Test("Detect Circular Dependencies")
        func circularDependencyDetected() throws {
            let container = try Assembler(CircularDependency()).container
            typealias A = CircularDependency.Classes.ObjectA
            typealias B = CircularDependency.Classes.ObjectB
            typealias C = CircularDependency.Classes.ObjectC
            typealias D = CircularDependency.Classes.ObjectD
            typealias E = CircularDependency.Classes.ObjectE
            typealias F = CircularDependency.Classes.ObjectF
            typealias G = CircularDependency.Classes.ObjectG
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(A.self)", name: nil)) {
                _ = try container.resolve(A.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(B.self)", name: nil)) {
                _ = try container.resolve(B.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(C.self)", name: nil)) {
                _ = try container.resolve(C.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(D.self)", name: nil)) {
                _ = try container.resolve(D.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(E.self)", name: nil)) {
                _ = try container.resolve(E.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(F.self)", name: nil)) {
                _ = try container.resolve(F.self)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(G.self)", name: nil)) {
                _ = try container.resolve(G.self)
            }
        }
        
        @Test("Named Circular Dependencies")
        func namedCircularDependencies() throws {
            let container = try Assembler(CircularDependency()).container
            typealias A = CircularDependency.Classes.ObjectA
            typealias B = CircularDependency.Classes.ObjectB
            typealias C = CircularDependency.Classes.ObjectC
            typealias D = CircularDependency.Classes.ObjectD
            typealias E = CircularDependency.Classes.ObjectE
            typealias F = CircularDependency.Classes.ObjectF
            typealias G = CircularDependency.Classes.ObjectG
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(A.self)", name: "test")) {
                _ = try container.resolve(A.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(B.self)", name: "test")) {
                _ = try container.resolve(B.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(C.self)", name: "test")) {
                _ = try container.resolve(C.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(D.self)", name: "test")) {
                _ = try container.resolve(D.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(E.self)", name: "test")) {
                _ = try container.resolve(E.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(F.self)", name: "test")) {
                _ = try container.resolve(F.self, name: "test")
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(G.self)", name: "test")) {
                _ = try container.resolve(G.self, name: "test")
            }
        }
        
        @Test("Argument Circular Dependencies")
        func circularDependenciesWithArguments() throws {
            let container = try Assembler(CircularDependency()).container
            typealias A = CircularDependency.Classes.ObjectA
            typealias B = CircularDependency.Classes.ObjectB
            typealias C = CircularDependency.Classes.ObjectC
            typealias D = CircularDependency.Classes.ObjectD
            typealias E = CircularDependency.Classes.ObjectE
            typealias F = CircularDependency.Classes.ObjectF
            typealias G = CircularDependency.Classes.ObjectG
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(A.self)", name: "test")) {
                _ = try container.resolve(A.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(B.self)", name: "test")) {
                _ = try container.resolve(B.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(C.self)", name: "test")) {
                _ = try container.resolve(C.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(D.self)", name: "test")) {
                _ = try container.resolve(D.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(E.self)", name: "test")) {
                _ = try container.resolve(E.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(F.self)", name: "test")) {
                _ = try container.resolve(F.self, argument: 1)
            }
            
            #expect(throws: AstrojectError.cyclicDependency(type: "\(G.self)", name: "test")) {
                _ = try container.resolve(G.self, argument: 1)
            }
        }
    }
}

// MARK: Instance Tests
extension SyncContainerTests {
    @Suite("Instance")
    struct InstanceTests {
        
        @Test("Singleton Instance")
        func containerSingletonInstance() throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            
            var count = 0
            try container.register(G.self) { _ in
                count += 1
                return G()
            }
            .asSingleton()
            
            let one = try container.resolve(G.self)
            let two = try container.resolve(G.self)
            
            #expect(one === two)
            #expect(count == 1)
        }
        
        @Test("Transient Instance")
        func containerTransientInstance() throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            
            var count = 0
            try container.register(G.self) { _ in
                count += 1
                return G()
            }
            .asTransient()
            
            let one = try container.resolve(G.self)
            let two = try container.resolve(G.self)
            
            #expect(one !== two)
            #expect(count == 2)
        }
        
        @Test("Weak Instance")
        func containerWeakInstance() throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            
            var count = 0
            try container.register(G.self) { _ in
                count += 1
                return G()
            }
            .asWeak()
            
            var one: G? = try container.resolve(G.self)
            var two: G? = try container.resolve(G.self)
            
            #expect(one === two)
            #expect(count == 1)
            
            let oneId = one!.id
            one = nil
            two = nil
            let three = try container.resolve(G.self)
            #expect(three.id != oneId)
            #expect(count == 2)
        }
        
        @Test("Graph Instance")
        func containerGraphInstance() throws {
            let container = SyncContainer()
            typealias B = Classes.ObjectB
            typealias C = Classes.ObjectC
            typealias D = Classes.ObjectD
            
            var cCount = 0
            var dCount = 0
            var bCount = 0
            
            try container.register(D.self) {
                dCount += 1
                return D()
            }
            
            try container.register(C.self) { resolver in
                cCount += 1
                let d = try resolver.resolve(D.self)
                return C(d: d)
            }
            
            try container.register(B.self) { resolver in
                bCount += 1
                let c = try resolver.resolve(C.self)
                let d = try resolver.resolve(D.self)
                return B(c: c, d: d)
            }
            
            _ = try container.resolve(B.self)
            
            #expect(bCount == 1)
            #expect(cCount == 1)
            #expect(dCount == 1)
        }
        
        @Test("Graph Instance with different identifiers")
        func containerGraphInstanceDifferentGraphs() throws {
            let container = SyncContainer()
            typealias B = Classes.ObjectB
            typealias C = Classes.ObjectC
            typealias D = Classes.ObjectD
            
            var dCount = 0
            var cCount = 0
            var bCount = 0
            try container.register(D.self) {
                dCount += 1
                return D()
            }
            
            try container.register(C.self) { resolver in
                cCount += 1
                let d = try resolver.resolve(D.self)
                return C(d: d)
            }
            
            try container.register(B.self) { resolver in
                bCount += 1
                let c = try resolver.resolve(C.self)
                let d = try resolver.resolve(D.self)
                return B(c: c, d: d)
            }
            
            _ = try container.resolve(B.self)
            _ = try container.resolve(B.self)
            
            #expect(bCount == 2)
            #expect(cCount == 2)
            #expect(dCount == 2)
        }
        
        @Test("Graph Instance - Complex dependencies")
        // swiftlint:disable:next function_body_length
        func containerGraphInstanceComplexDependencies() throws {
            let container = SyncContainer()
            typealias A = Classes.ObjectA
            typealias B = Classes.ObjectB
            typealias C = Classes.ObjectC
            typealias D = Classes.ObjectD
            
            var singletonCount = 0
            var graphCount = 0
            var transientCount = 0
            var weakCount = 0
            
            try container.register(D.self) { _ in
                singletonCount += 1
                return D()
            }
            .asSingleton()
            
            try container.register(C.self) { resolver in
                graphCount += 1
                let d = try resolver.resolve(D.self)
                return C(d: d)
            }
            
            try container.register(B.self) { resolver in
                transientCount += 1
                let c = try resolver.resolve(C.self)
                let d = try resolver.resolve(D.self)
                return B(c: c, d: d)
            }
            .asTransient()
            
            try container.register(A.self) { resolver in
                weakCount += 1
                let b = try resolver.resolve(B.self)
                let c = try resolver.resolve(C.self)
                let d = try resolver.resolve(D.self)
                let d2 = try resolver.resolve(D.self)
                return A(b: b, c: c, d: d, d2: d2)
            }
            .asWeak()
            
            var a: A? = try container.resolve(A.self)
            
            #expect(weakCount == 1)
            #expect(transientCount == 2)
            #expect(graphCount == 1)
            #expect(singletonCount == 1)
            
            var a2: A? = try container.resolve(A.self)
            
            // There are no changes because the object was never resolved!
            #expect(weakCount == 1)
            #expect(transientCount == 2)
            #expect(graphCount == 1)
            #expect(singletonCount == 1)
            
            a = nil
            a2 = nil
            
            _ = try container.resolve(A.self)
            
            #expect(weakCount == 2)
            #expect(transientCount == 4)
            #expect(graphCount == 2)
            #expect(singletonCount == 1)
            
            // added to remove some warnings
            #expect(a == nil)
            #expect(a2 == nil)
        }
        
        @Test("Context.current is unique per resolution tree")
        func contextGraphIDUniquenessPerTree() throws {
            let container = SyncContainer()
            var graphIDs: [UUID] = []
            
            // Register a simple type that captures the current graphID
            try container.register(UUID.self) { _ in
                let graphID = Context.current.graphID
                graphIDs.append(graphID)
                return graphID
            }
            
            // First resolution
            _ = try container.resolve(UUID.self)
            // Second resolution
            _ = try container.resolve(UUID.self)
            // Third resolution
            _ = try container.resolve(UUID.self)
            
            // You should have 3 different graphIDs
            #expect(graphIDs.count == 3)
            #expect(Set(graphIDs).count == 3)
        }
        
        @Test("Graph scope reuses the same context within one tree")
        func graphScopeSharesSameContext() throws {
            let container = SyncContainer()
            var capturedGraphIDs: [UUID] = []
            
            class O1 {}
            class O2 {}
            
            try container.register(O2.self) { _ in
                capturedGraphIDs.append(Context.current.graphID)
                return O2()
            }
            
            try container.register(O1.self) { resolver in
                _ = try resolver.resolve(O2.self)
                _ = try resolver.resolve(O2.self)
                capturedGraphIDs.append(Context.current.graphID)
                return O1()
            }
            
            _ = try container.resolve(O1.self)
            
            #expect(capturedGraphIDs.count == 2)
            #expect(Set(capturedGraphIDs).count == 1) // All the same!
        }
        
        @Test("Concurrent Graph Resolution")
        func containerConcurrentGraphResolution() async throws {
            let container = SyncContainer()
            typealias G = Classes.ObjectG
            let serialQueue = DispatchQueue(label: "com.astrobytes.astroject.tests.graph")
            var count = 0
            
            try container.register(G.self) {
                serialQueue.sync {
                    count += 1
                }
                return G()
            }
            
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        _ = try container.resolve(G.self)
                    }
                }
                try await group.waitForAll()
            }
            
            #expect(count == 10)
        }
    }
}

// swiftlint:enable identifier_name
// swiftlint:enable force_cast
// swiftlint:enable type_name
// swiftlint:enable nesting
// swiftlint:enable line_length
