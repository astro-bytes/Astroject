// No default isolation. The cost of @Sendable factories: capturing a non-Sendable
// value no longer compiles. Register it with `register(_:instance:)` and resolve it.
import AstrojectUnified

final class Database {}

final class Repository {
    let db: Database
    init(db: Database) { self.db = db }
}

func assemble(_ container: UnifiedContainer) {
    let db = Database()
    container.register(Repository.self) { _ in Repository(db: db) }
}
