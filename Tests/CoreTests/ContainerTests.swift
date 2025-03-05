//
//  Test.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Testing
import Foundation
@testable import Core

@Suite("Container")
struct ContainerTests {
    // MARK: Registration
    @Suite("Registration")
    struct RegistrationTests {
        @Test func registration() throws {
            let container = Container()
            let factory = Factory<Int> { _ in 42 }
            try container.register(Int.self, factory: factory)
            let expected = Registration(factory: factory, isOverridable: true)
            let key = RegistrationKey(productType: Int.self)
            let registration = container.registrations.getValue(for: key) as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test func namedRegistration() throws {
            let container = Container()
            let factory = Factory { _ in 42 }
            try container.register(Int.self, name: "42", factory: factory)
            let expected = Registration(factory: factory, isOverridable: true)
            let key = RegistrationKey(productType: Int.self, name: "42")
            let registration = container.registrations.getValue(for: key) as! Registration<Int>
            #expect(registration == expected)
        }
        
        @Test func noRegistrationFoundError() async throws {
            let container = Container()
            
            await #expect(throws: ResolutionError.noRegistrationFound) {
                try await container.resolve(Double.self)
            }
            
            await #expect(throws: ResolutionError.noRegistrationFound) {
                try await container.resolve(Double.self, name: "42")
            }
            
            try container.register(Double.self) { _ in 42 }
            await #expect(throws: ResolutionError.noRegistrationFound) {
                try await container.resolve(Double.self, name: "42")
            }
            
            container.clear()
            
            try container.register(Double.self, name: "42") { _ in 42 }
            await #expect(throws: ResolutionError.noRegistrationFound) {
                try await container.resolve(Double.self)
            }
        }
        
        @Test func registrationAlreadyExistsError() throws {
            let container = Container()
            
            #expect(throws: RegistrationError.alreadyRegistered(type: Int.self, name: nil)) {
                try container.register(Int.self, isOverridable: false) { _ in 42 }
                try container.register(Int.self) { _ in 41 }
            }
            
            #expect(throws: RegistrationError.alreadyRegistered(type: String.self, name: nil)) {
                try container.register(String.self) { _ in "41" }
                try container.register(String.self, isOverridable: false) { _ in "42" }
            }
        }
        
        @Test func clearRegistrations() throws {
            let container = Container()
            try container.register(Double.self) { _ in 42 }
            
            #expect(container.registrations.count == 1)
            
            container.clear()
            
            #expect(container.registrations.isEmpty)
        }
    }
    
    // MARK: Resolution
    @Suite("Resolution")
    struct ResolutionTests {
        @Test func resolution() async throws {
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
        
        @Test func namedResolution() async throws {
            let container = Container()
            try container.register(Int.self, name: "41") { _ in 41 }
            try container.register(Int.self, name: "42") { _ in 42 }
            let resolved41 = try await container.resolve(Int.self, name: "41")
            let resolved42 = try await container.resolve(Int.self, name: "42")
            #expect(resolved41 == 41)
            #expect(resolved42 == 42)
        }
        
        @Test func underlyingFactoryError() async throws {
            let container = Container()
            let error = NSError(domain: "Test", code: 123)
            try container.register(Int.self) { _ in throw error }
            await #expect(throws: ResolutionError.underlyingError(error)) {
                try await container.resolve(Int.self)
            }
        }
    }
    
    // MARK: Thread Safety
    @Suite("ThreadSafety")
    struct ThreadSafetyTests {
        @Test func concurrentRegistration() async throws {
            let container = Container()
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        let type = i % 3 // Cycle through 3 types
                        switch type {
                        case 0:
                            try! container.register(Int.self, name: "int\(i)") { i }
                        case 1:
                            try! container.register(String.self, name: "string\(i)") { "string\(i)" }
                        case 2:
                            try! container.register(Double.self, name: "double\(i)") { Double(i) }
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
        
        @Test func concurrentResolution() async throws {
            let container = Container()
            try! container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        _ = try! await container.resolve(Int.self, name: nil)
                    }
                }
            }
        }
        
        @Test func concurrentRegistrationAndResolution() async throws {
            let container = Container()
            try! container.register(Int.self) { 42 }
            let iterations = 100
            
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        if i % 2 == 0 {
                            try! container.register(String.self, name: "string\(i)") { "string\(i)" }
                        } else {
                            _ = try! await container.resolve(Int.self, name: nil)
                        }
                    }
                }
            }
            
            // Verify registrations
            for i in 0..<iterations where i % 2 == 0 {
                #expect(container.isRegistered(String.self, with: "string\(i)"))
            }
        }
        
        @Test func concurrentBehaviorAddition() async throws {
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
        
        @Test func concurrentClear() async throws {
            let container = Container()
            try! container.register(Int.self) { 42 }
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
    }
    
    // MARK: Other
    @Test func isRegistered() throws {
        let container = Container()
        try container.register(Int.self) { 42 }
        try container.register(String.self, name: "test") { "test" }
        
        #expect(container.isRegistered(Int.self, with: nil))
        #expect(container.isRegistered(String.self, with: "test"))
        #expect(!container.isRegistered(Double.self, with: nil))
        #expect(!container.isRegistered(Int.self, with: "test"))
    }
    
    @Test func addBehavior() throws {
        let container = Container()
        let behavior1 = MockBehavior()
        let behavior2 = MockBehavior()
        
        container.add(behavior1)
        container.add(behavior2)
        
        #expect(container.behaviors.count == 2)
        #expect((container.behaviors[0] as? MockBehavior) === behavior1)
        #expect((container.behaviors[1] as? MockBehavior) === behavior2)
    }
    
    @Test func findRegistration() throws {
        let container = Container()
        let factory = Factory<Int> { _ in 42 }
        try container.register(Int.self, factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: nil)
        #expect(registration.factory == factory)
        
        #expect(throws: ResolutionError.noRegistrationFound) {
            _ = try container.findRegistration(for: Double.self, with: nil)
        }
    }
    
    @Test func findNamedRegistration() throws {
        let container = Container()
        let factory = Factory<Int> { _ in 42 }
        try container.register(Int.self, name: "test", factory: factory)
        
        let registration = try container.findRegistration(for: Int.self, with: "test")
        #expect(registration.factory == factory)
        
        #expect(throws: ResolutionError.noRegistrationFound) {
            _ = try container.findRegistration(for: Int.self, with: "wrongName")
        }
    }
    
    @Test func removeRegistrationKey() throws {
        let container = Container()
        container.removeRegistrationKey(for: Int.self, with: nil)
        #expect(container.resolvingKeys.isEmpty)
    }
    
    @Test func removeNamedRegistrationKey() throws {
        let container = Container()
        container.removeRegistrationKey(for: Int.self, with: "test")
        #expect(container.resolvingKeys.isEmpty)
    }
    
    @Test func circularDependencyDetected() async throws {
        let container = Container()
        try container.register(CircularDependencyA.self) { resolver in
            let classB = try await resolver.resolve(CircularDependencyB.self)
            return CircularDependencyA(classB: classB)
        }
        
        try container.register(CircularDependencyB.self) { resolver in
            let classA = try await resolver.resolve(CircularDependencyA.self)
            return CircularDependencyB(classA: classA)
        }
        
        await #expect(throws: ResolutionError.circularDependencyDetected) {
            _ = try await container.resolve(CircularDependencyA.self)
        }
    }
    
    @Test func assertRegistrationAllowed() throws {
        let container = Container()
        let factory = Factory<Int> { _ in 42 }
        
        try container.register(Int.self, factory: factory)
        try container.register(Int.self, factory: factory) // Should succeed, as it's overridable
        
        #expect(throws: RegistrationError.alreadyRegistered(type: String.self, name: nil)) {
            try container.register(String.self, isOverridable: false) { "test" }
            try container.register(String.self) { "test2" }
        }
    }
}
