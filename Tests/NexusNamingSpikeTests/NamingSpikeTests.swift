//
//  NamingSpikeTests.swift
//  Astroject
//
//  Temporary spike for #15: can Nexus's API be named `register(_:initializer:)`
//  without changing which overload existing trailing-closure calls pick?
//

import Testing
import AstrojectCore
import AstrojectSync
import AstrojectNexus

extension Container {
    @discardableResult
    func register<Product, each Dependency>(
        _ productType: Product.Type,
        name: String? = nil,
        isOverridable: Bool = true,
        initializer: @escaping (repeat each Dependency) throws -> Product
    ) throws -> any Registrable<Product> {
        try autoregister(productType, name: name, isOverridable: isOverridable, initializer: initializer)
    }
}

final class Engine {
    init() {}
}

final class Car {
    let engine: Engine
    init(engine: Engine) { self.engine = engine }
}

@Suite("Naming spike")
struct NamingSpikeTests {
    @Test("Labeled initializer call uses the pack overload")
    func labeledInitializer() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        try container.register(Car.self, initializer: Car.init)
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Trailing closure with a resolver parameter still picks block:")
    func trailingClosureWithResolver() throws {
        let container = SyncContainer()
        try container.register(Engine.self, initializer: Engine.init)
        // If this picked the pack overload, `resolver` would be a dependency of type
        // Resolver, which is not registered, and resolve would throw.
        try container.register(Car.self) { resolver in
            Car(engine: try resolver.resolve(Engine.self))
        }
        
        _ = try container.resolve(Car.self)
    }
    
    @Test("Trailing closure with no parameters still compiles and resolves")
    func trailingClosureWithoutParameters() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 42 }
        
        #expect(try container.resolve(Int.self) == 42)
    }
    
    @Test("Trailing closure with a typed resolver parameter")
    func trailingClosureTypedResolver() throws {
        let container = SyncContainer()
        try container.register(Engine.self) { (_: Resolver) in Engine() }
        
        _ = try container.resolve(Engine.self)
    }
}
