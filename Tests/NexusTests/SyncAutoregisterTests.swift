//
//  SyncAutoregisterTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import Testing
@testable import AstrojectCore
@testable import AstrojectSync
@testable import AstrojectNexus

@Suite("Autoregister: SyncContainer")
struct SyncAutoregisterTests {
    func makeContainer() throws -> SyncContainer {
        let container = SyncContainer()
        try container.autoregister(Engine.self, initializer: Engine.init)
        try container.autoregister(Wheels.self, initializer: Wheels.init)
        return container
    }
    
    @Test("No dependencies")
    func noDependencies() throws {
        let container = SyncContainer()
        try container.autoregister(Engine.self, initializer: Engine.init)
        
        #expect(container.isRegistered(Engine.self))
        _ = try container.resolve(Engine.self)
    }
    
    @Test("Several dependencies")
    func severalDependencies() throws {
        let container = try makeContainer()
        try container.autoregister(Car.self, initializer: Car.init)
        
        let car = try container.resolve(Car.self)
        let engine = try container.resolve(Engine.self)
        
        #expect(car.engine !== engine)
    }
    
    @Test("Five dependencies")
    func fiveDependencies() throws {
        let container = try makeContainer()
        try container.autoregister(Car.self, initializer: Car.init)
        try container.autoregister(String.self) { "Main garage" }
        try container.autoregister(Garage.self, initializer: Garage.init)
        
        let garage = try container.resolve(Garage.self)
        
        #expect(garage.name == "Main garage")
    }
    
    @Test("Any function can be the initializer")
    func closureInitializer() throws {
        let container = try makeContainer()
        try container.autoregister(Car.self) { (engine: Engine, wheels: Wheels) in
            Car(engine: engine, wheels: wheels)
        }
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Named registration")
    func namedRegistration() throws {
        let container = SyncContainer()
        try container.autoregister(Engine.self, name: "v8", initializer: Engine.init)
        
        #expect(container.isRegistered(Engine.self, with: "v8"))
        #expect(!container.isRegistered(Engine.self))
        _ = try container.resolve(Engine.self, name: "v8")
        #expect(throws: AstrojectError.self) {
            try container.resolve(Engine.self)
        }
    }
    
    @Test("Non-overridable registration")
    func nonOverridable() throws {
        let container = SyncContainer()
        try container.autoregister(Engine.self, isOverridable: false, initializer: Engine.init)
        
        #expect(throws: AstrojectError.self) {
            try container.autoregister(Engine.self, initializer: Engine.init)
        }
    }
    
    @Test("Singleton scope")
    func singletonScope() throws {
        let container = try makeContainer()
        try container.autoregister(Car.self, initializer: Car.init).asSingleton()
        
        let first = try container.resolve(Car.self)
        let second = try container.resolve(Car.self)
        
        #expect(first === second)
    }
    
    @Test("Transient scope")
    func transientScope() throws {
        let container = try makeContainer()
        try container.autoregister(Car.self, initializer: Car.init).asTransient()
        
        let first = try container.resolve(Car.self)
        let second = try container.resolve(Car.self)
        
        #expect(first !== second)
    }
    
    @Test("Missing dependency throws")
    func missingDependency() throws {
        let container = SyncContainer()
        try container.autoregister(Car.self, initializer: Car.init)
        
        #expect(throws: AstrojectError.self) {
            try container.resolve(Car.self)
        }
    }
    
    @Test("Circular dependency throws")
    func circularDependency() throws {
        let container = SyncContainer()
        try container.autoregister(Chicken.self, initializer: Chicken.init)
        try container.autoregister(Egg.self, initializer: Egg.init)
        
        #expect(throws: AstrojectError.self) {
            try container.resolve(Chicken.self)
        }
    }
    
    @Test("Inside an Assembly")
    func insideAssembly() throws {
        let container = try SyncContainer(assemblies: [VehicleAssembly()])
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Async initializer is rejected")
    func asyncInitializerRejected() throws {
        let container = SyncContainer()
        
        #expect(throws: AstrojectError.self) {
            try container.autoregister(Database.self, initializer: Database.init)
        }
    }
    
    @Test("Runtime argument")
    func runtimeArgument() throws {
        let container = try makeContainer()
        try container.autoregister(Puzzle.self, argumentType: String.self, initializer: Puzzle.init)
        
        #expect(container.isRegistered(Puzzle.self, and: String.self))
        let first = try container.resolve(Puzzle.self, argument: "puzzle-1")
        let second = try container.resolve(Puzzle.self, argument: "puzzle-2")
        
        #expect(first.id == "puzzle-1")
        #expect(second.id == "puzzle-2")
    }
    
    @Test("Runtime argument with a missing dependency throws")
    func runtimeArgumentMissingDependency() throws {
        let container = SyncContainer()
        try container.autoregister(Puzzle.self, argumentType: String.self, initializer: Puzzle.init)
        
        #expect(throws: AstrojectError.self) {
            try container.resolve(Puzzle.self, argument: "puzzle-1")
        }
    }
    
    @Test("Async initializer with an argument is rejected")
    func asyncArgumentInitializerRejected() throws {
        let container = SyncContainer()
        
        #expect(throws: AstrojectError.self) {
            try container.autoregister(AsyncPuzzle.self, argumentType: String.self, initializer: AsyncPuzzle.init)
        }
    }
}
