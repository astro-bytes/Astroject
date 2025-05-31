//
//  FactoryTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Factory Tests")
struct FactoryTests {
    typealias F = Factory<Int, String>
    
    @Test("Equality")
    func whenAllIsEqual() {
        let syncBlock: F.Block = .sync { _ in 1 }
        let asyncBlock: F.Block = .async { _ in 1 }
        let factory1 = F(syncBlock)
        let factory2 = F(asyncBlock)
        let factory3 = F(asyncBlock)
        
        #expect(factory1 != factory2)
        #expect(factory2 != factory3)
        #expect(factory1 == factory1)
    }
    
    @Suite("Async Tests")
    struct AsyncTests {
        @Test("Rethrows Errors Async")
        func whenUnderlyingErrors_rethrowError() async throws {
            let block1: F.Block = .async { _ in throw MockError() }
            let block2: F.Block = .sync { _ in throw MockError() }
            let factory1 = F(block1)
            let factory2 = F(block2)
            
            await #expect(throws: MockError.self) {
                _ = try await factory1("")
            }
            
            await #expect(throws: MockError.self) {
                _ = try await factory2("")
            }
        }
        
        @Test("Factory Overloaded Call As Function")
        func factory_overloadCallAsFunction() async throws {
            let block1: F.Block = .sync { _ in 1 }
            let block2: F.Block = .async { _ in 2 }
            let factory1 = F(block1)
            let factory2 = F(block2)
            
            let result1 = try await factory1("")
            let result2 = try await factory2("")
            
            #expect(result1 == 1)
            #expect(result2 == 2)
        }
        
        @Test("Block Overloaded Call As Function")
        func block_overloadCallAsFunction() async throws {
            let block1: F.Block = .sync { _ in 1 }
            let block2: F.Block = .async { _ in 2 }
            
            let result1 = try await block1("")
            let result2 = try await block2("")
            
            #expect(result1 == 1)
            #expect(result2 == 2)
        }
    }
    
    @Suite("Sync Tests")
    struct SyncTests {
        @Test("Rethrows Errors Sync")
        func whenUnderlyingError_rethrowError() throws {
            let block1: F.Block = .async { _ in throw MockError() }
            let block2: F.Block = .sync { _ in throw MockError() }
            let factory1 = F(block1)
            let factory2 = F(block2)
            
            #expect(throws: AstrojectError.invalidFactory) {
                _ = try factory1("")
            }
            
            #expect(throws: MockError.self) {
                _ = try factory2("")
            }
        }
        
        @Test("Factory Overloaded Call As Function")
        func factory_overloadCallAsFunction() throws {
            let block1: F.Block = .sync { _ in 1 }
            let block2: F.Block = .async { _ in 2 }
            let factory1 = F(block1)
            let factory2 = F(block2)
            
            let result1 = try factory1("")
            #expect(result1 == 1)
            
            #expect(throws: AstrojectError.invalidFactory) {
                _ = try factory2("")
            }
        }
        
        @Test("Block Overloaded Call As Function")
        func block_overloadCallAsFunction() throws {
            let block1: F.Block = .sync { _ in 1 }
            let block2: F.Block = .async { _ in 2 }
            
            let result1 = try block1("")
            #expect(result1 == 1)
            
            #expect(throws: AstrojectError.invalidFactory) {
                _ = try block2("")
            }
        }
    }
}
