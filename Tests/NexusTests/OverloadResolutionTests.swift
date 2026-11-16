//
//  OverloadResolutionTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import Testing
@testable import AstrojectCore
@testable import AstrojectSync
@testable import AstrojectAsync
@testable import AstrojectNexus

/// Nexus adds `register(_:initializer:)` next to the existing `register(_:block:)` overloads.
/// These tests pin down that trailing-closure calls keep picking the `block:` overloads,
/// and that a labeled initializer picks the parameter pack overload.
@Suite("Overload resolution")
struct OverloadResolutionTests {
    @Test("Labeled initializer uses the pack overload (sync)")
    func labeledInitializerSync() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Wheels.self, initializer: Wheels.init)
        try container.register(Car.self, initializer: Car.init)
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Trailing closure with a resolver picks block: (sync)")
    func trailingResolverSync() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Wheels.self, initializer: Wheels.init)
        // If this picked the pack overload, `resolver` would be a dependency of type
        // Resolver, which is not registered, so resolve would throw.
        try container.register(Car.self) { resolver in
            Car(engine: try resolver.resolve(Engine.self), wheels: try resolver.resolve(Wheels.self))
        }
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Trailing closure with no parameters (sync)")
    func trailingNoParametersSync() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 42 }
        
        #expect(try container.resolve(Int.self) == 42)
    }
    
    @Test("Trailing closure with a typed resolver (sync)")
    func trailingTypedResolverSync() throws {
        let container = SyncContainer()
        try container.register(Engine.self) { (_: Resolver) in Engine() }
        
        _ = try container.resolve(Engine.self)
    }
    
    @Test("Trailing closure with a resolver and an argument picks block: (sync)")
    func trailingArgumentSync() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Puzzle.self, argumentType: String.self) { resolver, id in
            Puzzle(id: id, engine: try resolver.resolve(Engine.self))
        }
        
        let puzzle = try container.resolve(Puzzle.self, argument: "puzzle-1")
        
        #expect(puzzle.id == "puzzle-1")
    }
    
    @Test("Labeled initializer uses the pack overload (async)")
    func labeledInitializerAsync() async throws {
        let container = AsyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(FuelStation.self, initializer: FuelStation.init)
        
        _ = try await container.resolve(FuelStation.self)
    }
    
    @Test("Trailing closure with a resolver picks block: (async)")
    func trailingResolverAsync() async throws {
        let container = AsyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(FuelStation.self) { resolver in
            await FuelStation(engine: try await resolver.resolve(Engine.self))
        }
        
        _ = try await container.resolve(FuelStation.self)
    }
    
    @Test("Trailing closure with a resolver and an argument picks block: (async)")
    func trailingArgumentAsync() async throws {
        let container = AsyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(AsyncPuzzle.self, argumentType: String.self) { resolver, id in
            await AsyncPuzzle(id: id, engine: try await resolver.resolve(Engine.self))
        }
        
        let puzzle = try await container.resolve(AsyncPuzzle.self, argument: "puzzle-1")
        
        #expect(puzzle.id == "puzzle-1")
    }
}
