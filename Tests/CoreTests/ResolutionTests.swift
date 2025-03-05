//
//  ResolutionTests.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Core

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
    
    
    
    @Test func circularDependencyError() async throws {
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
    
    @Test func underlyingFactoryError() async throws {
        let container = Container()
        let error = NSError(domain: "Test", code: 123)
        try container.register(Int.self) { _ in throw error }
        await #expect(throws: error) {
            try await container.resolve(Int.self)
        }
    }
}
