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
            let context = Context.fresh()
            instance.set(dog, for: context)
            let result = instance.get(for: context)
            #expect(result != nil)
            #expect(result === dog)
        }
        
        @Test("Get returns same instance")
        func singletonSameInstance() {
            let instance = Singleton<ClassAnimal>()
            let dog = ClassAnimal()
            let context = Context.fresh()
            instance.set(dog, for: context)
            let result1 = instance.get(for: context)
            let result2 = instance.get(for: context)
            #expect(result1 === result2)
        }
    }
    
    @Suite("Transient")
    struct TransientTests {
        @Test("Get returns nil before set")
        func transientGetNil() {
            let instance = Transient<ClassAnimal>()
            let context = Context.fresh()
            let result = instance.get(for: context)
            #expect(result == nil)
        }
        
        @Test("Get returns different instances after set")
        func transientDifferentInstances() {
            let instance = Transient<ClassAnimal>()
            let context = Context.fresh()
            let dog1 = ClassAnimal()
            instance.set(dog1, for: context)
            let result1 = instance.get(for: context)
            let dog2 = ClassAnimal()
            instance.set(dog2, for: context)
            let result2 = instance.get(for: context)
            #expect(result1 == nil)
            #expect(result2 == nil)
        }
    }
    
    @Suite("Weak")
    struct WeakTests {
        @Test("Get and Set")
        func weakGetSet() {
            let instance = Weak<ClassAnimal>()
            let context = Context.fresh()
            var dog: ClassAnimal? = ClassAnimal()
            instance.set(dog!, for: context)
            var result = instance.get(for: context)
            #expect(result != nil)
            #expect(result === dog)
            dog = nil
            result = nil
            #expect(instance.get(for: context) == nil)
        }
        
        @Test("Instance becomes nil when original is deallocated")
        func weakBecomesNil() {
            let instance = Weak<ClassAnimal>()
            let context = Context.fresh()
            var dog: ClassAnimal? = ClassAnimal()
            instance.set(dog!, for: context)
            dog = nil
            #expect(instance.get(for: context) == nil)
        }
        
        @Test("Instance can hold structs")
        func weakStruct() {
            let instance = Weak<StructAnimal>()
            let context = Context.fresh()
            let animal = StructAnimal()
            instance.set(animal, for: context)
            instance.release(for: context)
            #expect(instance.get(for: context) == nil)
        }
    }
    
    @Suite("Graph")
    struct GraphTests {
        @Test("Get and Set")
        func graphGetSet() {
            let graph = Graph<ClassAnimal>()
            let context1 = Context.fresh()
            let dog1 = ClassAnimal()
            graph.set(dog1, for: context1)
            let result1 = graph.get(for: context1)
            #expect(result1 != nil)
            #expect(result1 === dog1)
            
            let context2 = Context.fresh()
            let dog2 = ClassAnimal()
            graph.set(dog2, for: context2)
            let result2 = graph.get(for: context2)
            #expect(result2 != nil)
            #expect(result2 === dog2)
            #expect(result1 !== result2) // Ensure different contexts, different instances
        }
        
        @Test("Get returns nil for unknown Context")
        func graphGetUnknownIdentifier() {
            let graph = Graph<ClassAnimal>()
            let unknownContext = Context.fresh()
            let result = graph.get(for: unknownContext)
            #expect(result == nil)
        }
        
        @Test("Release removes specific instance")
        func graphReleaseSpecific() {
            let graph = Graph<ClassAnimal>()
            let context1 = Context.fresh()
            let context2 = Context.fresh()
            let dog1 = ClassAnimal()
            let dog2 = ClassAnimal()
            graph.set(dog1, for: context1)
            graph.set(dog2, for: context2)
            
            graph.release(for: context1)
            
            #expect(graph.get(for: context1) == nil)
            #expect(graph.get(for: context2) === dog2)
        }
        
        @Test("ReleaseAll removes all instances")
        func graphReleaseAll() {
            let graph = Graph<ClassAnimal>()
            let context1 = Context.fresh()
            let context2 = Context.fresh()
            let dog1 = ClassAnimal()
            let dog2 = ClassAnimal()
            graph.set(dog1, for: context1)
            graph.set(dog2, for: context2)
            
            graph.releaseAll()
            
            #expect(graph.get(for: context1) == nil)
            #expect(graph.get(for: context2) == nil)
        }
    }
}
