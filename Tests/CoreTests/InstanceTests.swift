//  InstanceTests.swift
//  CoreTests
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import AstrojectCore

@Suite("Instance")
struct InstanceTests {
    @Suite("Singleton")
    struct SingletonTests {
        @Test("Get and Set")
        func singletonGetSet() {
            let instance = Singleton<ClassAnimal>()
            let dog = ClassAnimal()
            instance.set(dog)
            let result = instance.get()
            #expect(result != nil)
            #expect(result === dog)
        }
        
        @Test("Get returns same instance")
        func singletonSameInstance() {
            let instance = Singleton<ClassAnimal>()
            let dog = ClassAnimal()
            instance.set(dog)
            let result1 = instance.get()
            let result2 = instance.get()
            #expect(result1 === result2)
        }
    }
    
    @Suite("Prototype")
    struct PrototypeTests {
        @Test("Get returns nil before set")
        func prototypeGetNil() {
            let instance = Prototype<ClassAnimal>()
            let result = instance.get()
            #expect(result == nil)
        }
        
        @Test("Get returns different instances after set")
        func prototypeDifferentInstances() {
            let instance = Prototype<ClassAnimal>()
            let dog1 = ClassAnimal()
            instance.set(dog1)
            let result1 = instance.get()
            let dog2 = ClassAnimal()
            instance.set(dog2)
            let result2 = instance.get()
            #expect(result1 == nil)
            #expect(result2 == nil)
        }
    }
    
    @Suite("Weak")
    struct WeakTests {
        @Test("Get and Set")
        func weakGetSet() {
            let instance = Weak<ClassAnimal>()
            var dog: ClassAnimal? = ClassAnimal()
            instance.set(dog!)
            var result = instance.get()
            #expect(result != nil)
            #expect(result === dog)
            dog = nil
            result = nil
            #expect(instance.get() == nil)
        }
        
        @Test("Instance becomes nil when original is deallocated")
        func weakBecomesNil() {
            let instance = Weak<ClassAnimal>()
            var dog: ClassAnimal? = ClassAnimal()
            instance.set(dog!)
            dog = nil
            #expect(instance.get() == nil)
        }
    }
    
    @Suite("Graph")
    struct GraphTests {
        @Test("Get and Set")
        func graphGetSet() {
            let graph = Graph<ClassAnimal>()
            let identifier1 = Identifier()
            let dog1 = ClassAnimal()
            graph.set(dog1, for: identifier1)
            let result1 = graph.get(for: identifier1)
            #expect(result1 != nil)
            #expect(result1 === dog1)
            
            let identifier2 = Identifier()
            let dog2 = ClassAnimal()
            graph.set(dog2, for: identifier2)
            let result2 = graph.get(for: identifier2)
            #expect(result2 != nil)
            #expect(result2 === dog2)
            #expect(result1 !== result2) // Ensure different identifiers, different instances
        }
        
        @Test("Get returns nil for unknown Identifier")
        func graphGetUnknownIdentifier() {
            let graph = Graph<ClassAnimal>()
            let unknownIdentifier = Identifier()
            let result = graph.get(for: unknownIdentifier)
            #expect(result == nil)
        }
        
        @Test("Release removes specific instance")
        func graphReleaseSpecific() {
            let graph = Graph<ClassAnimal>()
            let identifier1 = Identifier()
            let identifier2 = Identifier()
            let dog1 = ClassAnimal()
            let dog2 = ClassAnimal()
            graph.set(dog1, for: identifier1)
            graph.set(dog2, for: identifier2)
            
            graph.release(for: identifier1)
            
            #expect(graph.get(for: identifier1) == nil)
            #expect(graph.get(for: identifier2) === dog2)
        }
        
        @Test("ReleaseAll removes all instances")
        func graphReleaseAll() {
            let graph = Graph<ClassAnimal>()
            let identifier1 = Identifier()
            let identifier2 = Identifier()
            let dog1 = ClassAnimal()
            let dog2 = ClassAnimal()
            graph.set(dog1, for: identifier1)
            graph.set(dog2, for: identifier2)
            
            graph.release()
            
            #expect(graph.get(for: identifier1) == nil)
            #expect(graph.get(for: identifier2) == nil)
        }
    }
}
