import Foundation
import Synchronization
import AstrojectUnified

// Plain, non-Sendable app types.

final class Database {
    let id = UUID()
    static func open() async throws -> Database {
        try await Task.sleep(for: .milliseconds(5))
        return Database()
    }
}

final class Repository {
    let db: Database
    init(db: Database) { self.db = db }
}

final class Logger {
    let id = UUID()
}

/// A non-Sendable type with an async initializer.
final class Report {
    let id = UUID()
    let db: Database
    init(db: Database) async throws {
        try await Task.sleep(for: .milliseconds(1))
        self.db = db
    }
}

/// A Sendable type with an async initializer, used as a lazy shared instance.
final class RemoteConfig: Sendable {
    let id = UUID()
    init(counter: Counter) async throws {
        counter.increment()
        try await Task.sleep(for: .milliseconds(20))
    }
}

final class Counter: Sendable {
    private let value = Mutex(0)
    func increment() { value.withLock { $0 += 1 } }
    var count: Int { value.withLock { $0 } }
}

actor ImageCache {
    private var hits = 0
    func hit() -> Int {
        hits += 1
        return hits
    }
}

@MainActor
final class ProfileViewModel {
    let repository: Repository
    let logger: Logger
    init(repository: Repository, logger: Logger) {
        self.repository = repository
        self.logger = logger
    }
}

@MainActor
final class ProfileScreenModel {
    let profile: ProfileViewModel
    init(profile: ProfileViewModel) { self.profile = profile }
}

final class CycleA {
    init(b: CycleB) {}
}

final class CycleB {
    init(a: CycleA) {}
}

struct DataAssembly: Assembly, AsyncSetup {
    func setUp(container: UnifiedContainer) async throws {
        let db = try await Database.open()
        container.register(Database.self, instance: db)
    }

    func assemble(container: UnifiedContainer) throws {
        container.register(Repository.self) { r in
            Repository(db: try r.resolve(Database.self))
        }
    }
}

struct LoggingAssembly: Assembly {
    func assemble(container: UnifiedContainer) throws {
        container.register(Logger.self) { _ in Logger() }.asSingleton()
    }
}
