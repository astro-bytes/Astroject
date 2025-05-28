////  InstanceTests.swift
////  CoreTests
////
////  Created by Porter McGary on 2/27/25.
////
//
//import Testing
//import Foundation
//@testable import Mocks
//@testable import AstrojectCore
//
//@Suite("Instance")
//struct InstanceTests {
//    typealias G = Classes.ObjectG
//    
//    @Suite("Singleton")
//    struct SingletonTests {
//        @Test("Get and Set")
//        func singletonGetSet() {
//            let instance = Singleton<G>()
//            let g = G()
//            let context = Context.fresh()
//            instance.set(g, for: context)
//            let result = instance.get(for: context)
//            #expect(result != nil)
//            #expect(result === g)
//        }
//        
//        @Test("Get returns same instance")
//        func singletonSameInstance() {
//            let instance = Singleton<G>()
//            let g = G()
//            let context = Context.fresh()
//            instance.set(g, for: context)
//            let result1 = instance.get(for: context)
//            let result2 = instance.get(for: context)
//            #expect(result1 === result2)
//        }
//    }
//    
//    @Suite("Transient")
//    struct TransientTests {
//        @Test("Get returns nil before set")
//        func transientGetNil() {
//            let instance = Transient<G>()
//            let context = Context.fresh()
//            let result = instance.get(for: context)
//            #expect(result == nil)
//        }
//        
//        @Test("Get returns different instances after set")
//        func transientDifferentInstances() {
//            let instance = Transient<G>()
//            let context = Context.fresh()
//            let g1 = G()
//            instance.set(g1, for: context)
//            let result1 = instance.get(for: context)
//            let g2 = G()
//            instance.set(g2, for: context)
//            let result2 = instance.get(for: context)
//            #expect(result1 == nil)
//            #expect(result2 == nil)
//        }
//    }
//    
//    @Suite("Weak")
//    struct WeakTests {
//        @Test("Get and Set")
//        func weakGetSet() {
//            let instance = Weak<G>()
//            let context = Context.fresh()
//            var g: G? = G()
//            instance.set(g!, for: context)
//            var result = instance.get(for: context)
//            #expect(result != nil)
//            #expect(result === g)
//            g = nil
//            result = nil
//            #expect(instance.get(for: context) == nil)
//        }
//        
//        @Test("Instance becomes nil when original is deallocated")
//        func weakBecomesNil() {
//            let instance = Weak<G>()
//            let context = Context.fresh()
//            var g: G? = G()
//            instance.set(g!, for: context)
//            g = nil
//            #expect(instance.get(for: context) == nil)
//        }
//        
//        @Test("Instance can hold structs")
//        func weakStruct() {
//            typealias G = Structs.ObjectG
//            let instance = Weak<G>()
//            let context = Context.fresh()
//            var g: G? = G()
//            instance.set(g!, for: context)
//            g = nil
//            #expect(instance.get(for: context) == nil)
//        }
//    }
//    
//    @Suite("Graph")
//    struct GraphTests {
//        @Test("Get and Set")
//        func graphGetSet() {
//            let graph = Graph<G>()
//            let context1 = Context.fresh()
//            let g1 = G()
//            graph.set(g1, for: context1)
//            let result1 = graph.get(for: context1)
//            #expect(result1 != nil)
//            #expect(result1 === g1)
//            
//            let context2 = Context.fresh()
//            let g2 = G()
//            graph.set(g2, for: context2)
//            let result2 = graph.get(for: context2)
//            #expect(result2 != nil)
//            #expect(result2 === g2)
//            #expect(result1 !== result2) // Ensure different contexts, different instances
//        }
//        
//        @Test("Get returns nil for unknown Context")
//        func graphGetUnknownIdentifier() {
//            let graph = Graph<G>()
//            let unknownContext = Context.fresh()
//            let result = graph.get(for: unknownContext)
//            #expect(result == nil)
//        }
//        
//        @Test("Release removes specific instance")
//        func graphReleaseSpecific() {
//            let graph = Graph<G>()
//            let context1 = Context.fresh()
//            let context2 = Context.fresh()
//            let g1 = G()
//            let g2 = G()
//            graph.set(g1, for: context1)
//            graph.set(g2, for: context2)
//            
//            graph.release(for: context1)
//            
//            #expect(graph.get(for: context1) == nil)
//            #expect(graph.get(for: context2) === g2)
//        }
//        
//        @Test("ReleaseAll removes all instances")
//        func graphReleaseAll() {
//            let graph = Graph<G>()
//            let context1 = Context.fresh()
//            let context2 = Context.fresh()
//            let g1 = G()
//            let g2 = G()
//            graph.set(g1, for: context1)
//            graph.set(g2, for: context2)
//            
//            graph.releaseAll()
//            
//            #expect(graph.get(for: context1) == nil)
//            #expect(graph.get(for: context2) == nil)
//        }
//    }
//}
