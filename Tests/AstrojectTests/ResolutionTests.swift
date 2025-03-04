//
//  ResolutionTests.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Astroject

@Suite("Resolution")
struct ResolutionTests {
    @Test func resolution() async throws {
        let container = Container()
        try await container.register(Int.self) { _ in 42 }
        let resolvedValue: Int = try await container.resolve(Int.self)
        #expect(resolvedValue == 42)
        
        try await container.register(Animal.self) { _ in Dog(name: "joe") }
        let resolvedAnimal = try await container.resolve(Animal.self)
        #expect(resolvedAnimal.name == "joe")
        
        try await container.register(Dog.self) { _ in Dog(name: "jim") }
        let resolvedDog = try await container.resolve(Dog.self)
        #expect(resolvedDog.name == "jim")
        
        try await container.register(Cat.self) { _ in Cat(name: "john") }
        let resolvedCat = try await container.resolve(Cat.self)
        #expect(resolvedCat.name == "john")
        
        try await container.register(Home.self) { resolver in
            let dog = try await resolver.resolve(Dog.self)
            let cat = try await resolver.resolve(Cat.self)
            return Home(cat: cat, dog: dog)
        }
        
        let home = try await container.resolve(Home.self)
        let isDog = await home.dog.isEqual(to: resolvedDog)
        let isCat = await home.cat.isEqual(to: resolvedCat)
        #expect(isDog)
        #expect(isCat)
    }
    
    @Test func namedResolution() async throws {
        let container = Container()
        try await container.register(Int.self, name: "41") { _ in 41 }
        try await container.register(Int.self, name: "42") { _ in 42 }
        let resolved41 = try await container.resolve(Int.self, name: "41")
        let resolved42 = try await container.resolve(Int.self, name: "42")
        #expect(resolved41 == 41)
        #expect(resolved42 == 42)
    }
    
    @Test func circularDependencyError() async throws {
        let container = Container()
        try await container.register(ClassA.self) { resolver in
            let classB = try await resolver.resolve(ClassB.self)
            return ClassA(classB: classB)
        }
        
        try await container.register(ClassB.self) { resolver in
            let classA = try await resolver.resolve(ClassA.self)
            return ClassB(classA: classA)
        }
        
        await #expect(throws: ResolutionError.circularDependencyDetected) {
            try await container.resolve(ClassA.self)
        }
    }
    
    @Test func underlyingFactoryError() async throws {
        let container = Container()
        let error = NSError(domain: "Test", code: 123)
        try await container.register(Int.self) { _ in throw error }
        await #expect(throws: error) {
            try await container.resolve(Int.self)
        }
    }
}
