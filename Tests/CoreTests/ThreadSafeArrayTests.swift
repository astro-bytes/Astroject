//
//  ArrayTests.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Core

@Suite("Array")
struct ThreadSafeArrayTests {
    @Test func emptyInitialization() {
        let array = ThreadSafeArray<Int>()
        #expect(array.isEmpty)
        #expect(array.count == 0)
    }
    
    @Test func append() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        #expect(!array.isEmpty)
        #expect(array.count == 1)
        #expect(array.get(at: 0) == 1)
    }
    
    @Test func insert() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.insert(2, at: 0)
        #expect(array.count == 2)
        #expect(array.get(at: 0) == 2)
        #expect(array.get(at: 1) == 1)
        
        array.insert(3, at: 2)
        #expect(array.count == 3)
        #expect(array.get(at: 2) == 3)
        
        array.insert(4, at: 100)
        #expect(array.count == 3)
    }
    
    @Test func removeAt() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        array.append(3)
        array.remove(at: 1)
        #expect(array.count == 2)
        #expect(array.get(at: 0) == 1)
        #expect(array.get(at: 1) == 3)
        
        array.remove(at: 100)
        #expect(array.count == 2)
    }
    
    @Test func get() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        #expect(array.get(at: 0) == 1)
        #expect(array.get(at: 1) == nil)
    }
    
    @Test func forEach() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        array.append(3)
        var sum = 0
        array.forEach { sum += $0 }
        #expect(sum == 6)
    }
    
    @Test func map() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        let mapped = array.map { $0 * 2 }
        #expect(mapped == [2, 4])
    }
    
    @Test func filter() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        array.append(3)
        let filtered = array.filter { $0 > 1 }
        #expect(filtered == [2, 3])
    }
    
    @Test func removeAll() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        array.removeAll()
        #expect(array.isEmpty)
        #expect(array.count == 0)
    }
    
    @Test func contains() {
        let array = ThreadSafeArray<Int>()
        array.append(1)
        array.append(2)
        #expect(array.contains(1))
        #expect(!array.contains(3))
    }
    
    @Test func threadSafety() async {
        let array = ThreadSafeArray<Int>()
        let iterations = 1000
        
        // Concurrent Appends
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    array.append(i)
                }
            }
        }
        
        // Concurrent Reads (Count)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = array.count
                }
            }
        }
        
        // Concurrent Reads (Get)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = array.get(at: Int.random(in: 0..<iterations))
                }
            }
        }
        
        // Concurrent Removes
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    array.remove(at: Int.random(in: 0..<iterations))
                }
            }
        }
        
        #expect(array.count == iterations)
    }
}
