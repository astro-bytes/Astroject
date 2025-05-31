//
//  FactoryTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

/**
 📦 1. Initialization

  Factory can be initialized with a .sync block.
  Factory can be initialized with an .async block.
 ⚙️ 2. Synchronous Resolution

  .sync block returns the correct result when called synchronously.
  .sync block returns the correct result when called asynchronously.
  .sync block correctly propagates thrown errors.
 ⏳ 3. Asynchronous Resolution

  .async block returns the correct result when called asynchronously.
  Calling .async block synchronously throws AstrojectError.invalidFactory.
  .async block correctly propagates thrown errors.
 🟰 4. Equality

  Two different factories with the same closure are not equal (due to different UUIDs).
  A factory is equal to itself.
 🧪 5. Miscellaneous

  Factory handles complex arguments (e.g. custom structs, tuples).
  Factory supports Void arguments (()).
  Calling an async block from within a Task context works as expected.
  callAsFunction overloads correctly dispatch to the underlying block.
 */
@Suite("Factory Tests")
struct FactoryTests {
    typealias F = Factory<Int, String>
    
    @Test("Equality")
    func equality() {
        let syncBlock: F.Block = .sync { _ in 1 }
        let asyncBlock: F.Block = .async { _ in 1 }
        let factory1 = F(syncBlock)
        let factory2 = F(asyncBlock)
        let factory3 = F(asyncBlock)
        
        #expect(factory1 != factory2)
        #expect(factory2 != factory3)
        #expect(factory1 == factory1)
    }
    
    @Test("Overloaded Call As Function Async")
    func overloadCallAsFunctionAsync() async throws {
        let block1: F.Block = .sync { _ in 1 }
        let block2: F.Block = .async { _ in 2 }
        let factory1 = F(block1)
        let factory2 = F(block2)
        
        let result1 = try await factory1("")
        let result2 = try await factory2("")
        
        #expect(result1 == 1)
        #expect(result2 == 2)
    }
    
    @Test("Overloaded Call As Function Sync")
    func overloadCallAsFunctionSync() throws {
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
    
    @Test("Rethrows Errors Async")
    func rethrowsErrors() async throws {
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
    
    @Test("Rethrows Errors Sync")
    func rethrowsErrorsSync() throws {
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
    
    @Suite("Block Tests")
    struct BlockTests {
        @Test("Overloaded Call As Function Async")
        func overloadCallAsFunctionAsync() async throws {
            let block1: F.Block = .sync { _ in 1 }
            let block2: F.Block = .async { _ in 2 }
            
            let result1 = try await block1("")
            let result2 = try await block2("")
            
            #expect(result1 == 1)
            #expect(result2 == 2)
        }
        
        @Test("Overloaded Call As Function Sync")
        func overloadCallAsFunctionSync() throws {
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
