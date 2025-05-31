//
//  GraphTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Graph Instance")
struct GraphTests {
    @Test("Init with Empty Storage")
    func initialize() {
        let graph = Graph<Int>()
        
        #expect(graph.storage.isEmpty)
    }
    
    @Test("Get with Context")
    func getWithContext() {
        let graph = Graph<Int>()
        let context1 = Context.fresh()
        let context2 = Context.fresh()
        
        graph.set(1, for: context1)
        graph.set(2, for: context2)
        
        #expect(graph.get(for: context1) == 1)
        #expect(graph.get(for: context2) == 2)
    }
    
    @Test("Get with Unknown Context")
    func getWithUnknownContext() {
        let graph = Graph<Int>()
        
        graph.set(1, for: Context.fresh())
        
        #expect(graph.get(for: Context.fresh()) == nil)
    }
    
    @Test("Get After Overrided")
    func getAfterOverride() {
        let graph = Graph<Int>()
        let context = Context.fresh()
        
        graph.set(1, for: context)
        graph.set(2, for: context)
        
        #expect(graph.get(for: context) == 2)
    }
    
    @Test("Set with Unique Context")
    func setWithUniqueContext() {
        let graph = Graph<Int>()
        let context1 = Context.fresh()
        let context2 = Context.fresh()
        
        graph.set(1, for: context1)
        graph.set(2, for: context2)
        
        #expect(graph.storage[context1.graphID] == 1)
        #expect(graph.storage[context2.graphID] == 2)
    }
    
    @Test("Set with Same Context")
    func setOverridesWithSameContext() {
        let graph = Graph<Int>()
        let context = Context.fresh()
        
        graph.set(1, for: context)
        graph.set(2, for: context)
        
        #expect(graph.storage[context.graphID] == 2)
    }
    
    @Test("Release With Context")
    func releaseWithContext() {
        let graph = Graph<Int>()
        let context = Context.fresh()
        
        graph.set(1, for: context)
        graph.set(2, for: Context.fresh())
        graph.set(3, for: Context.fresh())
        graph.set(4, for: Context.fresh())
        graph.set(5, for: Context.fresh())
        
        graph.release(for: Context.fresh())
        #expect(graph.storage.count == 5)
        
        graph.release(for: context)
        #expect(graph.storage.count == 4)
        #expect(graph.storage[context.graphID] == nil)
    }
    
    @Test("Release All")
    func releaseAll() {
        let graph = Graph<Int>()
        
        graph.set(1, for: Context.fresh())
        graph.set(2, for: Context.fresh())
        graph.set(3, for: Context.fresh())
        graph.set(4, for: Context.fresh())
        graph.set(5, for: Context.fresh())
        
        graph.releaseAll()
        #expect(graph.storage.isEmpty)
    }
    
    @Test("Thread Safety")
    func threadSafety() async {
        let graph = Graph<Int>()
        var contexts = [Context]()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<500 {
                let context = Context.fresh()
                contexts.append(context)
                group.addTask {
                    graph.set(index, for: context)
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<500 {
                let context = contexts[index]
                group.addTask {
                    let result = graph.get(for: context)
                    #expect(result == index)
                }
            }
        }
    }
    
    @Test("Memory References")
    func classReference() {
        let graph = Graph<Classes.ObjectD>()
        let context = Context.fresh()
        let expected = Classes.ObjectD()
        
        graph.set(expected, for: context)
        
        #expect(graph.get(for: context) === expected)
    }
}
