//
//  AsyncAutoregisterTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import Testing
@testable import AstrojectCore
@testable import AstrojectAsync
@testable import AstrojectNexus

@Suite("Autoregister: AsyncContainer")
struct AsyncAutoregisterTests {
    func makeContainer() throws -> AsyncContainer {
        let container = AsyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Wheels.self, initializer: Wheels.init)
        return container
    }
    
    @Test("Async resolution mode")
    func resolutionMode() {
        #expect(AsyncContainer().resolutionMode == .async)
    }
    
    @Test("Sync initializer resolves dependencies asynchronously")
    func syncInitializer() async throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init)
        
        _ = try await container.resolve(Car.self)
    }
    
    @Test("Five dependencies")
    func fiveDependencies() async throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init)
        try container.register(String.self, initializer: { "Main garage" })
        try container.register(Garage.self, initializer: Garage.init)
        
        let garage = try await container.resolve(Garage.self)
        
        #expect(garage.name == "Main garage")
    }
    
    @Test("Async initializer")
    func asyncInitializer() async throws {
        let container = try makeContainer()
        try container.register(FuelStation.self, initializer: FuelStation.init)
        
        _ = try await container.resolve(FuelStation.self)
    }
    
    @Test("Singleton scope")
    func singletonScope() async throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init).asSingleton()
        
        let first = try await container.resolve(Car.self)
        let second = try await container.resolve(Car.self)
        
        #expect(first === second)
    }
    
    @Test("Missing dependency throws")
    func missingDependency() async throws {
        let container = AsyncContainer()
        try container.register(Car.self, initializer: Car.init)
        
        await #expect(throws: AstrojectError.self) {
            try await container.resolve(Car.self)
        }
    }
    
    @Test("Circular dependency throws")
    func circularDependency() async throws {
        let container = AsyncContainer()
        try container.register(Chicken.self, initializer: Chicken.init)
        try container.register(Egg.self, initializer: Egg.init)
        
        await #expect(throws: AstrojectError.self) {
            try await container.resolve(Chicken.self)
        }
    }
    
    @Test("Inside an Assembly")
    func insideAssembly() async throws {
        let container = try AsyncContainer(assemblies: [VehicleAssembly()])
        
        _ = try await container.resolve(Car.self)
    }
    
    @Test("Runtime argument")
    func runtimeArgument() async throws {
        let container = try makeContainer()
        try container.register(Puzzle.self, argumentType: String.self, initializer: Puzzle.init)
        
        let puzzle = try await container.resolve(Puzzle.self, argument: "puzzle-1")
        
        #expect(puzzle.id == "puzzle-1")
    }
    
    @Test("Async initializer with a runtime argument")
    func asyncRuntimeArgument() async throws {
        let container = try makeContainer()
        try container.register(AsyncPuzzle.self, argumentType: String.self, initializer: AsyncPuzzle.init)
        
        let puzzle = try await container.resolve(AsyncPuzzle.self, argument: "puzzle-1")
        
        #expect(puzzle.id == "puzzle-1")
    }
}
