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
    @Test func resolution() throws {
        let container = Container()
        try container.register(Int.self) { _ in 42 }
        let resolvedValue: Int = try container.resolve(Int.self)
        #expect(resolvedValue == 42)
        
        try container.register(Animal.self) { _ in Dog(name: "joe") }
        let resolvedAnimal = try container.resolve(Animal.self)
        #expect(resolvedAnimal.name == "joe")
        
        try container.register(Dog.self) { _ in Dog(name: "jim") }
        let resolvedDog = try container.resolve(Dog.self)
        #expect(resolvedDog.name == "jim")
        
        try container.register(Cat.self) { _ in Cat(name: "john") }
        let resolvedCat = try container.resolve(Cat.self)
        #expect(resolvedCat.name == "john")
        
        try container.register(Home.self) { resolver in
            let dog = try resolver.resolve(Dog.self)
            let cat = try resolver.resolve(Cat.self)
            return Home(cat: cat, dog: dog)
        }
        
        let home = try container.resolve(Home.self)
        #expect(home.cat == resolvedCat)
        #expect(home.dog == resolvedDog)
    }
    
    @Test func namedResolution() throws {
        let container = Container()
        try container.register(Int.self, name: "41") { _ in 41 }
        try container.register(Int.self, name: "42") { _ in 42 }
        let resolved41 = try container.resolve(Int.self, name: "41")
        let resolved42 = try container.resolve(Int.self, name: "42")
        #expect(resolved41 == 41)
        #expect(resolved42 == 42)
    }
    
    @Test func asyncResolution() async throws {
        let container = Container()
        try container.registerAsync(Int.self) { _ in 42 }
        let resolvedValue: Int = try await container.resolveAsync(Int.self)
        #expect(resolvedValue == 42)
        
        try container.registerAsync(Animal.self) { _ in Dog(name: "joe") }
        let resolvedAnimal = try await container.resolveAsync(Animal.self)
        #expect(resolvedAnimal.name == "joe")
        
        try container.registerAsync(Dog.self) { _ in Dog(name: "jim") }
        let resolvedDog = try await container.resolveAsync(Dog.self)
        #expect(resolvedDog.name == "jim")
        
        try container.registerAsync(Cat.self) { _ in Cat(name: "john") }
        let resolvedCat = try await container.resolveAsync(Cat.self)
        #expect(resolvedCat.name == "john")
        
        try container.registerAsync(Home.self) { resolver in
            let dog = try await resolver.resolveAsync(Dog.self)
            let cat = try await resolver.resolveAsync(Cat.self)
            return Home(cat: cat, dog: dog)
        }
        
        let home = try await container.resolveAsync(Home.self)
        #expect(home.cat == resolvedCat)
        #expect(home.dog == resolvedDog)
    }
    
    @Test func namedAsyncResolution() async throws {
        let container = Container()
        try container.registerAsync(String.self, name: "41") { _ in "Hello 41" }
        try container.registerAsync(String.self, name: "42") { _ in "Hello 42" }
        let resolved41 = try await container.resolveAsync(String.self, name: "41")
        let resolved42 = try await container.resolveAsync(String.self, name: "42")
        #expect(resolved41 == "Hello 41")
        #expect(resolved42 == "Hello 42")
    }
    
    @Test func asyncResolutionRequiredError() throws {
        let container = Container()
        try container.registerAsync(Int.self) { _ in 41 }
        #expect(throws: ResolutionError.asyncResolutionRequired) {
            try container.resolve(Int.self)
        }
    }
    
    @Test func circularDependencyError() throws {
        let container = Container()
        try container.register(ClassA.self) { resolver in
            let classB = try resolver.resolve(ClassB.self)
            return ClassA(classB: classB)
        }
        
        try container.register(ClassB.self) { resolver in
            let classA = try resolver.resolve(ClassA.self)
            return ClassB(classA: classA)
        }
        
        #expect(throws: ResolutionError.circularDependencyDetected) {
            try container.resolve(ClassA.self)
        }
    }
    
    @Test func underlyingFactoryError() throws {
        let container = Container()
        let error = NSError(domain: "Test", code: 123)
        try container.register(Int.self) { _ in throw error }
        #expect(throws: error) {
            try container.resolve(Int.self)
        }
    }
}
