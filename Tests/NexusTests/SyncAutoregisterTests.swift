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
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Wheels.self, initializer: Wheels.init)
        return container
    }
    
    @Test("No dependencies")
    func noDependencies() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        
        #expect(container.isRegistered(Engine.self))
        _ = try container.resolve(Engine.self)
    }
    
    @Test("Several dependencies")
    func severalDependencies() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init)
        
        let car = try container.resolve(Car.self)
        let engine = try container.resolve(Engine.self)
        
        #expect(car.engine !== engine)
    }
    
    @Test("Five dependencies")
    func fiveDependencies() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init)
        try container.register(String.self, initializer: { "Main garage" })
        try container.register(Garage.self, initializer: Garage.init)
        
        let garage = try container.resolve(Garage.self)
        
        #expect(garage.name == "Main garage")
    }
    
    @Test("Any function can be the initializer")
    func closureInitializer() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: { (engine: Engine, wheels: Wheels) in
            Car(engine: engine, wheels: wheels)
        })
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Named registration")
    func namedRegistration() throws {
        let container = SyncContainer()
        try container.register(Engine.self, name: "v8", initializer: Engine.init)
        
        #expect(container.isRegistered(Engine.self, with: "v8"))
        #expect(!container.isRegistered(Engine.self))
        _ = try container.resolve(Engine.self, name: "v8")
        #expect(throws: AstrojectError.self) {
            try container.resolve(Engine.self)
        }
    }
    
    @Test("A later registration replaces an earlier one")
    func lastRegistrationWins() throws {
        let container = SyncContainer()
        try container.register(String.self, initializer: { "first" })
        try container.register(String.self, initializer: { "second" })
        
        #expect(try container.resolve(String.self) == "second")
    }
    
    @Test("Singleton scope")
    func singletonScope() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init).asSingleton()
        
        let first = try container.resolve(Car.self)
        let second = try container.resolve(Car.self)
        
        #expect(first === second)
    }
    
    @Test("Transient scope")
    func transientScope() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init).asTransient()
        
        let first = try container.resolve(Car.self)
        let second = try container.resolve(Car.self)
        
        #expect(first !== second)
    }
    
    @Test("Weak scope")
    func weakScope() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init).asWeak()
        
        let first = try container.resolve(Engine.self)
        let second = try container.resolve(Engine.self)
        
        #expect(first === second)
    }
    
    @Test("Graph scope shares an instance within one resolution")
    func graphScope() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init).asGraph()
        try container.register(Wheels.self, initializer: Wheels.init)
        try container.register(Car.self, initializer: Car.init)
        try container.register(Dashboard.self, initializer: Dashboard.init)
        
        let first = try container.resolve(Dashboard.self)
        let second = try container.resolve(Dashboard.self)
        
        #expect(first.engine === first.car.engine)
        #expect(first.engine !== second.engine)
    }
    
    @Test("Implements forwards to another type")
    func implementsForwards() throws {
        let container = try makeContainer()
        try container.register(Car.self, initializer: Car.init)
            .asSingleton()
            .implements(Vehicle.self)
        
        let car = try container.resolve(Car.self)
        let vehicle = try container.resolve(Vehicle.self)
        
        #expect(car === vehicle)
    }
    
    @Test("Missing dependency throws")
    func missingDependency() throws {
        let container = SyncContainer()
        try container.register(Car.self, initializer: Car.init)
        
        #expect(throws: AstrojectError.self) {
            try container.resolve(Car.self)
        }
    }
    
    @Test("Circular dependency throws")
    func circularDependency() throws {
        let container = SyncContainer()
        try container.register(Chicken.self, initializer: Chicken.init)
        try container.register(Egg.self, initializer: Egg.init)
        
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
            try container.register(FuelStation.self, initializer: FuelStation.init)
        }
    }
    
    @Test("Runtime argument")
    func runtimeArgument() throws {
        let container = try makeContainer()
        try container.register(Puzzle.self, argumentType: String.self, initializer: Puzzle.init)
        
        #expect(container.isRegistered(Puzzle.self, and: String.self))
        let first = try container.resolve(Puzzle.self, argument: "puzzle-1")
        let second = try container.resolve(Puzzle.self, argument: "puzzle-2")
        
        #expect(first.id == "puzzle-1")
        #expect(second.id == "puzzle-2")
    }
    
    @Test("Runtime argument with a missing dependency throws")
    func runtimeArgumentMissingDependency() throws {
        let container = SyncContainer()
        try container.register(Puzzle.self, argumentType: String.self, initializer: Puzzle.init)
        
        #expect(throws: AstrojectError.self) {
            try container.resolve(Puzzle.self, argument: "puzzle-1")
        }
    }
    
    @Test("Async initializer with an argument is rejected")
    func asyncArgumentInitializerRejected() throws {
        let container = SyncContainer()
        
        #expect(throws: AstrojectError.self) {
            try container.register(AsyncPuzzle.self, argumentType: String.self, initializer: AsyncPuzzle.init)
        }
    }
    
    @Test("Runtime argument with graph scope")
    func runtimeArgumentGraphScope() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init).asGraph()
        try container.register(Wheels.self, initializer: Wheels.init)
        try container.register(Car.self, initializer: Car.init)
        try container.register(Trip.self, argumentType: String.self, initializer: Trip.init)
        
        let first = try container.resolve(Trip.self, argument: "trip-1")
        let second = try container.resolve(Trip.self, argument: "trip-2")
        
        #expect(first.id == "trip-1")
        #expect(second.id == "trip-2")
        #expect(first.engine === first.car.engine)
        #expect(first.engine !== second.engine)
    }
}
