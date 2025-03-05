//
//  ThreadSafeDictionaryTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Core

// swiftlint:disable identifier_name

@Suite("ThreadSafeDictionary")
struct ThreadSafeDictionaryTests {
    
    @Test func emptyInitialization() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        #expect(dictionary.isEmpty)
        #expect(dictionary.count == 0)
    }
    
    @Test func initializationWithDictionary() {
        let initialDictionary = ["one": 1, "two": 2]
        let dictionary = ThreadSafeDictionary(from: initialDictionary)
        #expect(!dictionary.isEmpty)
        #expect(dictionary.count == 2)
        #expect(dictionary.getValue(for: "one") == 1)
        #expect(dictionary.getValue(for: "two") == 2)
    }
    
    @Test func getValue() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        #expect(dictionary.getValue(for: "one") == 1)
        #expect(dictionary.getValue(for: "two") == nil)
    }
    
    @Test func insert() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        #expect(!dictionary.isEmpty)
        #expect(dictionary.count == 1)
        #expect(dictionary.getValue(for: "one") == 1)
        
        dictionary.insert(2, for: "two")
        #expect(dictionary.count == 2)
        #expect(dictionary.getValue(for: "two") == 2)
        
        dictionary.insert(3, for: "one")
        #expect(dictionary.getValue(for: "one") == 3)
        #expect(dictionary.count == 2)
    }
    
    @Test func contains() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        #expect(dictionary.contains("one"))
        #expect(!dictionary.contains("two"))
    }
    
    @Test func forEach() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        dictionary.insert(2, for: "two")
        var sum = 0
        dictionary.forEach { sum += $0.value }
        #expect(sum == 3)
    }
    
    @Test func map() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        dictionary.insert(2, for: "two")
        
        let mapped = dictionary.map {
            $0.value * 2
        }.sorted {
            $0 < $1
        }
        
        #expect(mapped == [2, 4])
    }
    
    @Test func removeAll() {
        let dictionary = ThreadSafeDictionary<String, Int>()
        dictionary.insert(1, for: "one")
        dictionary.insert(2, for: "two")
        dictionary.removeAll()
        #expect(dictionary.isEmpty)
        #expect(dictionary.count == 0)
    }
    
    @Test func threadSafety() async {
        let dictionary = ThreadSafeDictionary<Int, Int>()
        let iterations = 1000
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    dictionary.insert(i, for: i)
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = dictionary.getValue(for: Int.random(in: 0..<iterations))
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    _ = dictionary.contains(Int.random(in: 0..<iterations))
                }
            }
        }
        
        #expect(dictionary.count == iterations)
    }
}

// swiftlint:enable identifier_name
