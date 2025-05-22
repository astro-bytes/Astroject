//
//  FactoryTests.swift
//  CoreTests
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Factory")
struct FactoryTests {
    @Test("Init")
    func initialization() {
        let factory = Factory { 10 }
        #expect(factory != Factory { 20 }) // Ensure UUIDs are different
    }
    
    @Test("Equality")
    func equality() {
        let factory1 = Factory { 10 }
        let factory2 = Factory { 10 }
        #expect(factory1 != factory2) // UUIDs are different, so not equal
    }
    
    @Test("Call as Function")
    func functionCall() async throws {
        let resolver = MockResolver()
        let factory = Factory { resolver in
            try await resolver.resolve(Int.self, name: nil) + 5
        }
        
        let result = try await factory(resolver)
        #expect(result == 47)
    }
    
    @Test("Call in Resolver")
    func callWithResolver() async throws {
        let resolver = MockResolver()
        let factory = Factory { resolver in
            try await resolver.resolve(String.self, name: nil) + " Appended"
        }
        
        let result = try await factory(resolver)
        #expect(result == "Test String Appended")
    }
    
    @Test("Throws Errors")
    func throwsError() async throws {
        let resolver = MockResolver()
        resolver.whenResolve = {
            throw MockError()
        }
        let factory = Factory { resolver in
            try await resolver.resolve(Double.self, name: nil)
        }
        
        await #expect(throws: MockError.self) {
            try await factory(resolver)
        }
    }
}
