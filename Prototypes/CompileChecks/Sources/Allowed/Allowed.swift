// Default main-actor isolation. The safe ways to write the registrations that the
// other targets get wrong.
import AstrojectUnified

final class Settings {
    var theme = "dark"
}

nonisolated final class Database {}

nonisolated final class Repository {
    let db: Database
    init(db: Database) { self.db = db }
}

func assemble(_ container: UnifiedContainer) {
    // Main-actor types go through registerMainActor.
    container.registerMainActor(Settings.self) { _ in Settings() }
    container.registerMainActor(String.self, name: "theme") { r in try r.resolve(Settings.self).theme }
    // A value made up front is registered as an instance, not captured.
    container.register(Database.self, instance: Database())
    container.register(Repository.self) { r in Repository(db: try r.resolve(Database.self)) }
}
