//
//  InjectableRuntimeTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
import AstrojectNexusMacros
import AstrojectSync
import AstrojectAsync

@Injectable
final class MacroEngine {
    init() {}
}

@Injectable(scope: .singleton)
final class MacroWheels {
    init() {}
}

@Injectable(name: "sports")
final class MacroCar {
    let engine: MacroEngine
    let wheels: MacroWheels
    
    init(engine: MacroEngine, wheels: MacroWheels) {
        self.engine = engine
        self.wheels = wheels
    }
}

@Injectable
struct MacroGarage {
    let engine: MacroEngine
    var wheels: MacroWheels
}

@Injectable(scope: .transient)
final class MacroDashboard {
    let engine: MacroEngine
    
    init() {
        self.engine = MacroEngine()
    }
    
    @InjectableInit
    init(engine: MacroEngine) {
        self.engine = engine
    }
}

@Injectable
final class MacroFuelStation {
    let engine: MacroEngine
    
    init(engine: MacroEngine) async {
        self.engine = engine
    }
}

protocol MacroRepository: AnyObject {}
protocol MacroCache: AnyObject {}

@Injectable(scope: .singleton, name: "remote", as: MacroRepository.self, MacroCache.self)
final class MacroRemoteRepository: MacroRepository, MacroCache {
    init(engine: MacroEngine) {}
}

@Suite("@Injectable at runtime")
struct InjectableRuntimeTests {
    func makeContainer() throws -> SyncContainer {
        let container = SyncContainer()
        try container.register(injectables: [
            MacroEngine.self,
            MacroWheels.self,
            MacroCar.self,
            MacroGarage.self,
            MacroDashboard.self
        ])
        return container
    }
    
    @Test("Resolves a class with dependencies, by name")
    func resolvesNamedClass() throws {
        let container = try makeContainer()
        let car = try container.resolve(MacroCar.self, name: "sports")
        
        #expect(car.wheels === (try container.resolve(MacroWheels.self)))
        #expect(!container.isRegistered(MacroCar.self))
    }
    
    @Test("Resolves a struct by its memberwise initializer")
    func resolvesMemberwiseStruct() throws {
        let container = try makeContainer()
        _ = try container.resolve(MacroGarage.self)
    }
    
    @Test("Applies the scope")
    func appliesScope() throws {
        let container = try makeContainer()
        
        #expect(try container.resolve(MacroWheels.self) === (try container.resolve(MacroWheels.self)))
        #expect(try container.resolve(MacroDashboard.self) !== (try container.resolve(MacroDashboard.self)))
    }
    
    @Test("Records the type's file and line")
    func recordsSource() throws {
        let container = try makeContainer()
        let entry = try #require(container.registrationReport().entries.first)
        
        #expect(entry.sources.first?.fileID == "NexusMacrosRuntimeTests/InjectableRuntimeTests.swift")
        #expect(entry.sources.first?.line == 13)
    }
    
    @Test("Registers an async initializer with an AsyncContainer")
    func registersAsyncInitializer() async throws {
        let container = AsyncContainer()
        try container.register(injectables: [MacroEngine.self, MacroFuelStation.self])
        
        _ = try await container.resolve(MacroFuelStation.self)
    }
    
    @Test("as: forwards each type to the same singleton")
    func forwardsToSameSingleton() throws {
        let container = try makeContainer()
        try container.register(injectables: [MacroRemoteRepository.self])
        
        let repository = try container.resolve(MacroRemoteRepository.self, name: "remote")
        let viaRepository = try container.resolve(MacroRepository.self, name: "remote")
        let viaCache = try container.resolve(MacroCache.self, name: "remote")
        
        #expect(repository === viaRepository)
        #expect(repository === viaCache)
    }
}
