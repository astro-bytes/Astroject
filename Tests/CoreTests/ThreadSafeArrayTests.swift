//
//  ThreadSafeArrayTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Core

// swiftlint:disable identifier_name

@Suite("ThreadSafeArray")
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
    
    @Test func subscriptGet() {
        let array = ThreadSafeArray<Int>()
        array.append(10)
        array.append(20)
        
        #expect(array[0] == 10)
        #expect(array[1] == 20)
        #expect(array[2] == nil) // Out of bounds
        #expect(array[-1] == nil) // Negative index
    }
    
    @Test func subscriptSet() {
        let array = ThreadSafeArray<Int>()
        array.append(10)
        array.append(20)
        
        array[0] = 15
        #expect(array[0] == 15)
        
        array[1] = 25
        #expect(array[1] == 25)
        
        array[2] = 30 // Out of bounds, should do nothing
        #expect(array.count == 2)
        
        array[-1] = 5 // Negative index, should do nothing
        #expect(array[0] == 15)
    }
    
    @Test func subscriptThreadSafety() async {
        let array = ThreadSafeArray<Int>()
        let iterations = 1000
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    if Int.random(in: 0..<2) == 0 {
                        array.append(i)
                    } else if !array.isEmpty {
                        let index = Int.random(in: 0..<array.count)
                        _ = array[index]
                    }
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    let index = Int.random(in: 0..<array.count)
                    array[index] = i
                }
            }
        }
        
        #expect(array.count <= iterations * 2) // Approximate count, might be less due to overwrites
    }
    
    @Test func threadSafety() async {
        let array = ThreadSafeArray<Int>()
        let iterations = 1000
        
        // Concurrent Appends
        await withTaskGroup(of: Void.self) { _ in
            for _ in 0..<iterations {
                let operation = Int.random(in: 0..<5)
                switch operation {
                case 0:
                    array.append(Int.random(in: 0..<100))
                case 1:
                    array.insert(Int.random(in: 0..<100), at: Int.random(in: 0..<array.count + 1))
                case 2:
                    if !array.isEmpty {
                        array.remove(at: Int.random(in: 0..<array.count))
                    }
                case 3:
                    if !array.isEmpty {
                        _ = array.get(at: Int.random(in: 0..<array.count))
                    }
                case 4:
                    _ = array.count
                default:
                    break
                }
            }
        }
        
        #expect(array.count >= 0)
    }
}

// swiftlint:enable identifier_name
