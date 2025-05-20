//
//  Test.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//
import Testing
import Foundation
@testable import AstrojectCore

// swiftlint:disable identifier_name
// swiftlint:disable force_cast
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

@Suite("Container")
struct ContainerTests {
    @Test("Validate isRegistered")
    func isRegistered() throws {
        let container = Container()
        try container.register(Int.self) { 42 }
        try container.register(String.self, name: "test") { "test" }
        
        #expect(container.isRegistered(Int.self, with: nil))
        #expect(container.isRegistered(String.self, with: "test"))
        #expect(!container.isRegistered(Double.self, with: nil))
        #expect(!container.isRegistered(Int.self, with: "test"))
    }
    
    @Test("Add a Behavior")
    func addBehavior() throws {
        let container = Container()
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
        let container = Container()
        let factory = Factory { _ in 42 }
        try container.register(Int.self, factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: nil)
        #expect(registration.factory == factory)
        
        #expect(throws: AstrojectError.noRegistrationFound) {
            _ = try container.findRegistration(for: Double.self, with: nil)
        }
    }
    
    @Test("Find a Named Registration")
    func findNamedRegistration() throws {
        let container = Container()
        let factory = Factory { 42 }
        try container.register(Int.self, name: "test", factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: "test")
        #expect(registration.factory == factory)
        
        #expect(throws: AstrojectError.noRegistrationFound) {
            _ = try container.findRegistration(for: Int.self, with: "wrongName")
        }
    }
    
    @Test("Detect Circular Dependencies")
    func circularDependencyDetected() async throws {
        let container = Container()
        try container.register(CircularDependencyA.self) { resolver in
            let classB = try await resolver.resolve(CircularDependencyB.self)
            return CircularDependencyA(classB: classB)
        }
        
        try container.register(CircularDependencyB.self) { resolver in
            let classA = try await resolver.resolve(CircularDependencyA.self)
            return CircularDependencyB(classA: classA)
        }
        
        await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyA.self)", name: nil)) {
            _ = try await container.resolve(CircularDependencyA.self)
        }
    }
    
    @Test("Validate Overriding Registration is Allowed")
    func assertRegistrationAllowed() throws {
        let container = Container()
        let factory = Factory { 42 }
        
        try container.register(Int.self, factory: factory)
        try container.register(Int.self, factory: factory) // Should succeed, as it's overridable
        
        #expect(throws: AstrojectError.alreadyRegistered(type: "\(String.self)", name: nil)) {
            try container.register(String.self, isOverridable: false) { "test" }
            try container.register(String.self) { "test2" }
        }
    }
    
    @Test("Clear all Registrations")
    func clearRegistrations() throws {
        let container = Container()
        try container.register(Double.self) { _ in 42 }
        
        #expect(container.registrations.count == 1)
        
        container.clear()
        
        #expect(container.registrations.isEmpty)
    }
}

// MARK: Registration
extension ContainerTests {
    @Suite("Registration")
    struct RegistrationTests {
        @Test("Registration Happy Path")
        func registration() throws {
            let container = Container()
            let factory = Factory { 42 }
            try container.register(Int.self, factory: factory)
            let expected = Registration(factory: factory, isOverridable: true, instance: Transient())
            let key = RegistrationKey(productType: Int.self)
            let registration = container.registrations[key] as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test("Validate Named Registration")
        func namedRegistration() throws {
            let container = Container()
            let factory = Factory { 42 }
            try container.register(Int.self, name: "42", factory: factory)
            let expected = Registration(factory: factory, isOverridable: true, instance: Transient())
            let key = RegistrationKey(productType: Int.self, name: "42")
            let registration = container.registrations[key] as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test("Throw No Registration Error")
        func noRegistrationFoundError() async throws {
            let container = Container()
            
            await #expect(throws: AstrojectError.noRegistrationFound) {
                try await container.resolve(Double.self)
            }
            
            await #expect(throws: AstrojectError.noRegistrationFound) {
                try await container.resolve(Double.self, name: "42")
            }
            
            try container.register(Double.self) { _ in 42 }
            await #expect(throws: AstrojectError.noRegistrationFound) {
                try await container.resolve(Double.self, name: "42")
            }
            
            container.clear()
            
            try container.register(Double.self, name: "42") { _ in 42 }
            await #expect(throws: AstrojectError.noRegistrationFound) {
                try await container.resolve(Double.self)
            }
        }
        
        @Test("Throw Already Registered Error")
        func registrationAlreadyExistsError() throws {
            let container = Container()
            
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
extension ContainerTests {
    @Suite("Resolution")
    struct ResolutionTests {
        @Test("Resolve Happy Path")
        func resolution() async throws {
            let container = Container()
            try container.register(Int.self) { _ in 42 }
            let resolvedValue: Int = try await container.resolve(Int.self)
            #expect(resolvedValue == 42)
            
            try container.register(Animal.self) { _ in ClassAnimal(name: "joe") }
            let resolvedAnimal = try await container.resolve(Animal.self)
            #expect(resolvedAnimal.name == "joe")
            
            try container.register(ClassAnimal.self) { _ in ClassAnimal(name: "jim") }
            let resolvedDog = try await container.resolve(ClassAnimal.self)
            #expect(resolvedDog.name == "jim")
            
            try container.register(StructAnimal.self) { _ in StructAnimal(name: "john") }
            let resolvedCat = try await container.resolve(StructAnimal.self)
            #expect(resolvedCat.name == "john")
            
            try container.register(Home.self) { resolver in
                let dog = try await resolver.resolve(ClassAnimal.self)
                let cat = try await resolver.resolve(StructAnimal.self)
                return Home(cat: cat, dog: dog)
            }
            
            let home = try await container.resolve(Home.self)
            #expect(home.cat == resolvedCat)
            #expect(home.dog == resolvedDog)
        }
        
        @Test("Named Resolution Happy Path")
        func namedResolution() async throws {
            let container = Container()
            try container.register(Int.self, name: "41") { _ in 41 }
            try container.register(Int.self, name: "42") { _ in 42 }
            let resolved41 = try await container.resolve(Int.self, name: "41")
            let resolved42 = try await container.resolve(Int.self, name: "42")
            #expect(resolved41 == 41)
            #expect(resolved42 == 42)
        }
        
        @Test("Argument Resolution Happy Path")
        func argumentResolution() async throws {
            class MyObject {
                let arg: String
                init(arg: String) { self.arg = arg }
            }
            
            let container = Container()
            try container.register(MyObject.self, argument: String.self) { (_, arg) in
                MyObject(arg: arg)
            }
            
            let first = try await container.resolve(MyObject.self, argument: "1")
            let second = try await container.resolve(MyObject.self, argument: "2")
            let third = try await container.resolve(MyObject.self, argument: "1")
            
            #expect(first !== second)
            #expect(third.arg == first.arg)
        }
        
        @Test("Throw Resolution Errro")
        func underlyingFactoryError() async throws {
            let container = Container()
            let error = NSError(domain: "Test", code: 123)
            try container.register(Int.self) { _ in throw error }
            await #expect(throws: AstrojectError.underlyingError(error)) {
                try await container.resolve(Int.self)
            }
        }
    }
}

// MARK: Thread Safety
extension ContainerTests {
    @Suite("Thread Safety")
    struct ThreadSafetyTests {
        @Test("Register Concurrently")
        func concurrentRegistration() async throws {
            let container = Container()
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
            let container = Container()
            try container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        await #expect(throws: Never.self) {
                            let result = try await container.resolve(Int.self)
                            #expect(result == 42)
                        }
                    }
                }
            }
        }
        
        @Test("Concurrent Registration and Resolution")
        func concurrentRegistrationAndResolution() async throws {
            let container = Container()
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
                            await #expect(throws: Never.self) {
                                let result = try await container.resolve(Int.self)
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
            let container = Container()
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
            let container = Container()
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
            let container = Container()
            try container.register(Int.self) { 42 }
            try container.register(String.self) { "hello" }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        if i % 2 == 0 {
                            await #expect(throws: Never.self) {
                                let result: Int = try await container.resolve(Int.self)
                                #expect(result == 42)
                            }
                        } else {
                            await #expect(throws: Never.self) {
                                let result: String = try await container.resolve(String.self)
                                #expect(result == "hello")
                            }
                        }
                    }
                }
            }
        }
        
        @Test("Concurrent Registration with the Same Type & Different Names")
        func concurrentRegistrationOfSameTypeWithDifferentNames() async throws {
            let container = Container()
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
            let container = Container()
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
                            let resolvedInt: Int? = try? await container.resolve(Int.self, name: "int\(i)")
                            #expect(resolvedInt == i)
                        }
                        if i % 7 == 0 {
                            let resolvedString: String? = try? await container.resolve(String.self, name: "string\(i)")
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
            
            let container = Container()
            // Register a shared dependency
            try container.register(SharedDependency.self) { SharedDependency() }
            
            // Register two types that depend on the shared dependency
            try container.register(ObjectA.self) { resolver in
                let shared = try await resolver.resolve(SharedDependency.self)
                return ObjectA(shared: shared)
            }
            try container.register(ObjectB.self) { resolver in
                let shared = try await resolver.resolve(SharedDependency.self)
                return ObjectB(shared: shared)
            }
            
            let iterations = 50
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        let a = try? await container.resolve(ObjectA.self)
                        let b = try? await container.resolve(ObjectB.self)
                        #expect(a != nil)
                        #expect(b != nil)
                    }
                }
            }
        }
    }
}

// MARK: Circular Dependency Tests
extension ContainerTests {
    @Suite("Circular Dependency")
    struct CircularDependencyTests {
        class CircularDependencyC {
            let classB: CircularDependencyA
            init(classB: CircularDependencyA) {
                self.classB = classB
            }
        }
        
        class CircularDependencyX {
            let y: CircularDependencyY
            init(y: CircularDependencyY) {
                self.y = y
            }
        }
        
        class CircularDependencyY {
            let z: CircularDependencyZ
            init(z: CircularDependencyZ) {
                self.z = z
            }
        }
        
        class CircularDependencyZ {
            let x: CircularDependencyX
            init(x: CircularDependencyX) {
                self.x = x
            }
        }
        
        class CircularDependencyWithArgA {
            let classB: CircularDependencyWithArgB
            init(classB: CircularDependencyWithArgB) {
                self.classB = classB
            }
        }
        
        class CircularDependencyWithArgB {
            let classA: CircularDependencyWithArgA
            init(classA: CircularDependencyWithArgA) {
                self.classA = classA
            }
        }
        
        @Test("Deep Circular Dependencies")
        func deeperCircularDependencies() async throws {
            let container = Container()
            try container.register(CircularDependencyA.self) { resolver in
                let b = try await resolver.resolve(CircularDependencyB.self)
                return CircularDependencyA(classB: b)
            }
            
            try container.register(CircularDependencyB.self) { resolver in
                let c = try await resolver.resolve(CircularDependencyC.self)
                return CircularDependencyB(classA: c.classB)
            }
            
            try container.register(CircularDependencyC.self) { resolver in
                let a = try await resolver.resolve(CircularDependencyA.self)
                return CircularDependencyC(classB: a)
            }
            
            await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyA.self)", name: nil)) {
                _ = try await container.resolve(CircularDependencyA.self)
            }
        }
        
        @Test("Named Circular Dependencies")
        func namedCircularDependencies() async throws {
            let container = Container()
            try container.register(CircularDependencyA.self, name: "a") { resolver in
                let b = try await resolver.resolve(CircularDependencyB.self, name: "b")
                return CircularDependencyA(classB: b)
            }
            
            try container.register(CircularDependencyB.self, name: "b") { resolver in
                let a = try await resolver.resolve(CircularDependencyA.self, name: "a")
                return CircularDependencyB(classA: a)
            }
            
            await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyA.self)", name: "a")) {
                _ = try await container.resolve(CircularDependencyA.self, name: "a")
            }
        }
        
        @Test("Argument Circular Dependencies")
        func circularDependenciesWithArguments() async throws {
            let container = Container()
            try container.register(CircularDependencyWithArgA.self, argument: Int.self) { resolver, arg in
                let b = try await resolver.resolve(CircularDependencyWithArgB.self, argument: arg)
                return CircularDependencyWithArgA(classB: b)
            }
            
            try container.register(CircularDependencyWithArgB.self, argument: Int.self) { resolver, arg in
                let a = try await resolver.resolve(CircularDependencyWithArgA.self, argument: arg)
                return CircularDependencyWithArgB(classA: a)
            }
            
            await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyWithArgA.self)", name: nil)) {
                _ = try await container.resolve(CircularDependencyWithArgA.self, argument: 1)
            }
        }
        
        @Test("Multiple Circular Dependency Scenarios")
        func multipleCircularDependencyScenarios() async throws {
            let container = Container()
            
            // Scenario 1: A -> B -> A
            try container.register(CircularDependencyA.self) { resolver in
                let b = try await resolver.resolve(CircularDependencyB.self)
                return CircularDependencyA(classB: b)
            }
            try container.register(CircularDependencyB.self) { resolver in
                let a = try await resolver.resolve(CircularDependencyA.self)
                return CircularDependencyB(classA: a)
            }
            
            await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyA.self)", name: nil)) {
                _ = try await container.resolve(CircularDependencyA.self)
            }
            
            container.clear()
            
            // Scenario 2: X -> Y -> Z -> X
            try container.register(CircularDependencyX.self) { resolver in
                let y = try await resolver.resolve(CircularDependencyY.self)
                return CircularDependencyX(y: y)
            }
            try container.register(CircularDependencyY.self) { resolver in
                let z = try await resolver.resolve(CircularDependencyZ.self)
                return CircularDependencyY(z: z)
            }
            try container.register(CircularDependencyZ.self) { resolver in
                let x = try await resolver.resolve(CircularDependencyX.self)
                return CircularDependencyZ(x: x)
            }
            
            await #expect(throws: AstrojectError.circularDependencyDetected(type: "\(CircularDependencyX.self)", name: nil)) {
                _ = try await container.resolve(CircularDependencyX.self)
            }
        }
    }
}

// MARK: Instance Tests
extension ContainerTests {
    @Suite("Instance")
    struct InstanceTests {
        class Object0 {
            let object1: Object1
            let secondObject1: Object1
            let object2: Object2
            let object3: Object3
            
            init(object1: Object1, secondObject1: Object1, object2: Object2, object3: Object3) {
                self.object1 = object1
                self.secondObject1 = secondObject1
                self.object2 = object2
                self.object3 = object3
            }
        }
        
        struct Object1 {
            let object2: Object2
            let object3: Object3
        }
        
        struct Object2 {
            let object3: Object3
        }
        
        class Object3 {
            let id = UUID()
        }
        
        struct Object4 {
            let id = UUID()
        }
        
        @Test("Singleton Instance")
        func containerSingletonInstance() async throws {
            let container = Container()
            
            var count = 0
            try container.register(Object3.self) { _ in
                count += 1
                return Object3()
            }
            .asSingleton()
            
            let one = try await container.resolve(Object3.self)
            let two = try await container.resolve(Object3.self)
            
            #expect(one === two)
            #expect(count == 1)
        }
        
        @Test("Transient Instance")
        func containerTransientInstance() async throws {
            let container = Container()
            
            var count = 0
            try container.register(Object3.self) { _ in
                count += 1
                return Object3()
            }
            .asTransient()
            
            let one = try await container.resolve(Object3.self)
            let two = try await container.resolve(Object3.self)
            
            #expect(one !== two)
            #expect(count == 2)
        }
        
        @Test("Weak Instance")
        func containerWeakInstance() async throws {
            let container = Container()
            
            var count = 0
            try container.register(Object3.self) { _ in
                count += 1
                return Object3()
            }
            .asWeak()
            
            var one: Object3? = try await container.resolve(Object3.self)
            var two: Object3? = try await container.resolve(Object3.self)
            
            #expect(one === two)
            #expect(count == 1)
            
            let oneId = one!.id
            one = nil
            two = nil
            let three = try await container.resolve(Object3.self)
            #expect(three.id != oneId)
            #expect(count == 2)
        }
        
        @Test("Graph Instance")
        func containerGraphInstance() async throws {
            let container = Container()
            
            var object3Count = 0
            var object2Count = 0
            var object1Count = 0
            try container.register(Object3.self) {
                object3Count += 1
                return Object3()
            }
            
            try container.register(Object2.self) { resolver in
                object2Count += 1
                let object3 = try await resolver.resolve(Object3.self)
                return Object2(object3: object3)
            }
            
            try container.register(Object1.self) { resolver in
                object1Count += 1
                let object3 = try await resolver.resolve(Object3.self)
                let object2 = try await resolver.resolve(Object2.self)
                return Object1(object2: object2, object3: object3)
            }
            
            _ = try await container.resolve(Object1.self)
            
            #expect(object3Count == 1)
            #expect(object2Count == 1)
            #expect(object1Count == 1)
        }
        
        @Test("Graph Instance with different identifiers")
        func containerGraphInstanceDifferentGraphs() async throws {
            let container = Container()
            
            var object3Count = 0
            var object2Count = 0
            var object1Count = 0
            try container.register(Object3.self) {
                object3Count += 1
                return Object3()
            }
            
            try container.register(Object2.self) { resolver in
                object2Count += 1
                let object3 = try await resolver.resolve(Object3.self)
                return Object2(object3: object3)
            }
            
            try container.register(Object1.self) { resolver in
                object1Count += 1
                let object3 = try await resolver.resolve(Object3.self)
                let object2 = try await resolver.resolve(Object2.self)
                return Object1(object2: object2, object3: object3)
            }
            
            _ = try await container.resolve(Object1.self)
            _ = try await container.resolve(Object1.self)
            
            #expect(object3Count == 2)
            #expect(object2Count == 2)
            #expect(object1Count == 2)
        }
        
        @Test("Graph Instance - Complex dependencies")
        func containerGraphInstanceComplexDependencies() async throws {
            let container = Container()
            
            var singletonCount = 0
            var graphCount = 0
            var transientCount = 0
            var weakCount = 0
            
            try container.register(Object3.self) { _ in
                singletonCount += 1
                return Object3()
            }
            .asSingleton()
            
            try container.register(Object2.self) { resolver in
                graphCount += 1
                let object3 = try await resolver.resolve(Object3.self)
                return Object2(object3: object3)
            }
            
            try container.register(Object1.self) { resolver in
                transientCount += 1
                let object3 = try await resolver.resolve(Object3.self)
                let object2 = try await resolver.resolve(Object2.self)
                return Object1(object2: object2, object3: object3)
            }
            .asTransient()
            
            try container.register(Object0.self) { resolver in
                weakCount += 1
                let object3 = try await resolver.resolve(Object3.self)
                let object2 = try await resolver.resolve(Object2.self)
                let object1 = try await resolver.resolve(Object1.self)
                let secondObject1 = try await resolver.resolve(Object1.self)
                return Object0(object1: object1, secondObject1: secondObject1, object2: object2, object3: object3)
            }
            .asWeak()
            
            var object0: Object0? = try await container.resolve(Object0.self)
            
            #expect(weakCount == 1)
            #expect(transientCount == 2)
            #expect(graphCount == 1)
            #expect(singletonCount == 1)
            
            var secondObject0: Object0? = try await container.resolve(Object0.self)
            
            // There are no changes because the object was never resolved!
            #expect(weakCount == 1)
            #expect(transientCount == 2)
            #expect(graphCount == 1)
            #expect(singletonCount == 1)
            
            object0 = nil
            secondObject0 = nil
            
            _ = try await container.resolve(Object0.self)
            
            #expect(weakCount == 2)
            #expect(transientCount == 4)
            #expect(graphCount == 2)
            #expect(singletonCount == 1)
            
            // added to remove some warnings
            #expect(object0 == nil)
            #expect(secondObject0 == nil)
        }
        
        @Test("Context.current is unique per resolution tree")
        func contextGraphIDUniquenessPerTree() async throws {
            let container = Container()
            var graphIDs: [UUID] = []
            
            // Register a simple type that captures the current graphID
            try container.register(UUID.self) { _ in
                let graphID = Context.current.graphID
                graphIDs.append(graphID)
                return graphID
            }
            
            // First resolution
            _ = try await container.resolve(UUID.self)
            // Second resolution
            _ = try await container.resolve(UUID.self)
            // Third resolution
            _ = try await container.resolve(UUID.self)
            
            // You should have 3 different graphIDs
            #expect(graphIDs.count == 3)
            #expect(Set(graphIDs).count == 3)
        }
        
        @Test("Graph scope reuses the same context within one tree")
        func graphScopeSharesSameContext() async throws {
            let container = Container()
            var capturedGraphIDs: [UUID] = []
            
            class O1 {}
            class O2 {}
            
            try container.register(O2.self) { _ in
                capturedGraphIDs.append(Context.current.graphID)
                return O2()
            }
            
            try container.register(O1.self) { resolver in
                _ = try await resolver.resolve(O2.self)
                _ = try await resolver.resolve(O2.self)
                capturedGraphIDs.append(Context.current.graphID)
                return O1()
            }
            
            _ = try await container.resolve(O1.self)
            
            #expect(capturedGraphIDs.count == 2)
            #expect(Set(capturedGraphIDs).count == 1) // All the same!
        }
        
        
        @Test("Concurrent Graph Resolution")
        func containerConcurrentGraphResolution() async throws {
            let container = Container()
            let serialQueue = DispatchQueue(label: "test.concurrency.graph.instances")
            var object3Count = 0
            
            try container.register(Object3.self) {
                serialQueue.sync {
                    object3Count += 1
                }
                return Object3()
            }
            
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        _ = try await container.resolve(Object3.self)
                    }
                }
                try await group.waitForAll()
            }
            
            #expect(object3Count == 10)
        }
        
    }
}
