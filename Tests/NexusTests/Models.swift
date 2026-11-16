//
//  Models.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import AstrojectCore

final class Engine {
    init() {}
}

final class Wheels {
    init() {}
}

final class Car {
    let engine: Engine
    let wheels: Wheels
    
    init(engine: Engine, wheels: Wheels) {
        self.engine = engine
        self.wheels = wheels
    }
}

struct Garage {
    let first: Car
    let second: Car
    let engine: Engine
    let wheels: Wheels
    let name: String
    
    init(first: Car, second: Car, engine: Engine, wheels: Wheels, name: String) {
        self.first = first
        self.second = second
        self.engine = engine
        self.wheels = wheels
        self.name = name
    }
}

final class FuelStation {
    let engine: Engine
    
    init(engine: Engine) async {
        self.engine = engine
    }
}

final class Puzzle {
    let id: String
    let engine: Engine
    
    init(id: String, engine: Engine) {
        self.id = id
        self.engine = engine
    }
}

final class AsyncPuzzle {
    let id: String
    let engine: Engine
    
    init(id: String, engine: Engine) async {
        self.id = id
        self.engine = engine
    }
}

protocol Vehicle: AnyObject {}

extension Car: Vehicle {}

final class Dashboard {
    let engine: Engine
    let car: Car
    
    init(engine: Engine, car: Car) {
        self.engine = engine
        self.car = car
    }
}

final class Trip {
    let id: String
    let engine: Engine
    let car: Car
    
    init(id: String, engine: Engine, car: Car) {
        self.id = id
        self.engine = engine
        self.car = car
    }
}

final class Chicken {
    init(egg: Egg) {}
}

final class Egg {
    init(chicken: Chicken) {}
}

struct VehicleAssembly: Assembly {
    func assemble(container: Container) throws {
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Wheels.self, initializer: Wheels.init)
        try container.register(Car.self, initializer: Car.init)
    }
}
