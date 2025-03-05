//
//  FactoryTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Core

@Suite("Factory")
struct FactoryTests {
    @Test func initialization() {
        let factory = Factory<Int> { _ in 10 }
        #expect(factory != Factory<Int> { _ in 20 }) // Ensure UUIDs are different
    }
    
    @Test func equality() {
        let factory1 = Factory<Int> { _ in 10 }
        let factory2 = Factory<Int> { _ in 10 }
        #expect(factory1 != factory2) // UUIDs are different, so not equal
    }
    
    @Test func functionCall() async throws {
        let resolver = MockResolver()
        let factory = Factory<Int> { resolver in
            try await resolver.resolve(Int.self, name: nil) + 5
        }
        
        let result = try await factory(resolver)
        #expect(result == 47)
    }
    
    @Test func callWithResolver() async throws {
        let resolver = MockResolver()
        let factory = Factory<String> { resolver in
            try await resolver.resolve(String.self, name: nil) + " Appended"
        }
        
        let result = try await factory(resolver)
        #expect(result == "Test String Appended")
    }
    
    @Test func throwsError() async throws {
        let resolver = MockResolver()
        let factory = Factory<Double> { resolver in
            try await resolver.resolve(Double.self, name: nil)
        }
        
        await #expect(throws: resolver.error) {
            try await factory(resolver)
        }
    }
}
