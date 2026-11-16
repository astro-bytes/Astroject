//
//  ReadmeExamplesTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/15/26.
//

import Testing
import AstrojectCore
import AstrojectSync
import AstrojectAsync
import AstrojectNexus

// Keep these in step with the Nexus section of README.md: each test body is the README code as written.

private final class Logger {
    init() {}
}

private final class UserRepository {
    let logger: Logger
    init(logger: Logger) { self.logger = logger }
}

private final class UserService {
    let repository: UserRepository
    let logger: Logger
    init(repository: UserRepository, logger: Logger) {
        self.repository = repository
        self.logger = logger
    }
}

private final class Database {
    init(logger: Logger) async { /* open a connection */ }
}

private final class PuzzleViewModel {
    let puzzleID: String
    let repository: UserRepository
    init(puzzleID: String, repository: UserRepository) {
        self.puzzleID = puzzleID
        self.repository = repository
    }
}

@Suite("README examples")
struct ReadmeExamplesTests {
    @Test("Before and after")
    func beforeAndAfter() throws {
        let container = SyncContainer()
        
        // Before: a closure that resolves each parameter by hand
        try container.register(Logger.self) { Logger() }
        try container.register(UserRepository.self) { resolver in
            UserRepository(logger: try resolver.resolve(Logger.self))
        }
        try container.register(UserService.self) { resolver in
            UserService(
                repository: try resolver.resolve(UserRepository.self),
                logger: try resolver.resolve(Logger.self)
            )
        }
        
        // After: pass the initializer
        try container.register(Logger.self, initializer: Logger.init).asSingleton()
        try container.register(UserRepository.self, initializer: UserRepository.init)
        try container.register(UserService.self, initializer: UserService.init)
        
        let service = try container.resolve(UserService.self)
        
        #expect(service.logger === service.repository.logger)
    }
    
    @Test("Any function as the initializer")
    func closureInitializer() throws {
        let container = SyncContainer()
        try container.register(Logger.self, initializer: Logger.init)
        try container.register(UserRepository.self, initializer: UserRepository.init)
        
        try container.register(UserService.self, initializer: { (repository: UserRepository, logger: Logger) in
            UserService(repository: repository, logger: logger)
        })
        
        _ = try container.resolve(UserService.self)
    }
    
    @Test("Async initializers")
    func asyncInitializers() async throws {
        let asyncContainer = AsyncContainer()
        try asyncContainer.register(Logger.self, initializer: Logger.init)
        try asyncContainer.register(Database.self, initializer: Database.init)
        
        let database = try await asyncContainer.resolve(Database.self)
        
        _ = database
    }
    
    @Test("Async initializer on SyncContainer throws invalidFactory")
    func asyncOnSyncContainer() throws {
        let container = SyncContainer()
        
        #expect(throws: AstrojectError.invalidFactory) {
            try container.register(Database.self, initializer: Database.init)
        }
    }
    
    @Test("One runtime argument")
    func runtimeArgument() throws {
        let container = SyncContainer()
        try container.register(Logger.self, initializer: Logger.init)
        try container.register(UserRepository.self, initializer: UserRepository.init)
        
        try container.register(PuzzleViewModel.self, argumentType: String.self, initializer: PuzzleViewModel.init)
        
        let viewModel = try container.resolve(PuzzleViewModel.self, argument: "puzzle-42")
        
        #expect(viewModel.puzzleID == "puzzle-42")
    }
}
