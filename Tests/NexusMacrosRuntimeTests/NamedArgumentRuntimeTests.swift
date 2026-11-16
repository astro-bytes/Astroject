//
//  NamedArgumentRuntimeTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
import AstrojectNexusMacros
import AstrojectSync
import AstrojectAsync

final class MacroLogger {
    let label: String
    
    init(label: String) {
        self.label = label
    }
}

@Injectable
final class MacroAnalytics {
    let logger: MacroLogger
    let engine: MacroEngine
    
    init(@Named("analytics") logger: MacroLogger, engine: MacroEngine) {
        self.logger = logger
        self.engine = engine
    }
}

enum MacroDifficulty {
    case easy, hard
}

@Injectable
final class MacroPuzzleViewModel {
    let puzzleID: String
    let difficulty: MacroDifficulty
    let logger: MacroLogger
    
    init(
        @Argument puzzleID: String,
        @Argument difficulty: MacroDifficulty,
        @Named("analytics") logger: MacroLogger
    ) {
        self.puzzleID = puzzleID
        self.difficulty = difficulty
        self.logger = logger
    }
}

@Injectable
final class MacroLoader {
    let path: String
    
    init(@Argument path: String, engine: MacroEngine) async throws {
        self.path = path
    }
}

@Suite("@Named and @Argument at runtime")
struct NamedArgumentRuntimeTests {
    func makeContainer() throws -> SyncContainer {
        let container = SyncContainer()
        try container.register(MacroLogger.self, name: "analytics", factory: Factory(.sync { _ in
            MacroLogger(label: "analytics")
        }))
        try container.register(MacroLogger.self, factory: Factory(.sync { _ in MacroLogger(label: "default") }))
        try container.register(injectables: [MacroEngine.self, MacroAnalytics.self, MacroPuzzleViewModel.self])
        return container
    }
    
    @Test("@Named resolves the parameter by name")
    func namedResolvesByName() throws {
        let container = try makeContainer()
        let analytics = try container.resolve(MacroAnalytics.self)
        
        #expect(analytics.logger.label == "analytics")
    }
    
    @Test("@Named resolves by name in an AsyncContainer")
    func namedResolvesAsync() async throws {
        let container = AsyncContainer()
        try container.register(MacroLogger.self, name: "analytics", factory: Factory(.async { _ in
            MacroLogger(label: "analytics")
        }))
        try container.register(injectables: [MacroEngine.self, MacroAnalytics.self])
        let analytics = try await container.resolve(MacroAnalytics.self)
        
        #expect(analytics.logger.label == "analytics")
    }
    
    @Test("@Argument registers a Factory that takes the arguments")
    func argumentMakesFactory() throws {
        let container = try makeContainer()
        let factory = try container.resolve(MacroPuzzleViewModel.Factory.self)
        let viewModel = try factory.make(puzzleID: "42", difficulty: .hard)
        
        #expect(viewModel.puzzleID == "42")
        #expect(viewModel.difficulty == .hard)
        #expect(viewModel.logger.label == "analytics")
        #expect(!container.isRegistered(MacroPuzzleViewModel.self))
    }
    
    @Test("An async initializer's Factory makes it asynchronously")
    func asyncFactory() async throws {
        let container = AsyncContainer()
        try container.register(injectables: [MacroEngine.self, MacroLoader.self])
        let factory = try await container.resolve(MacroLoader.Factory.self)
        let loader = try await factory.make(path: "/tmp")
        
        #expect(loader.path == "/tmp")
    }
}
