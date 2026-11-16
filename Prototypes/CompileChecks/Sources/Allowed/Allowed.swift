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

/// Main-actor isolated, with an explicit (so main-actor) init.
final class Profile {
    let name: String
    init(name: String) { self.name = name }
}

func assemble(_ container: UnifiedContainer) {
    // A synthesized init of a main-actor class is nonisolated, so a plain closure may
    // build one anywhere. That's safe: the object is main-actor isolated (and so
    // Sendable), and every use of its state still has to be on the main actor.
    container.register(Settings.self, name: "fresh") { _ in Settings() }
    // Main-actor types go through registerMainActor.
    container.registerMainActor(Settings.self) { _ in Settings() }
    container.registerMainActor(Profile.self) { _ in Profile(name: "Porter") }
    container.registerMainActor(String.self, name: "theme") { r in try r.resolve(Settings.self).theme }
    // A value made up front is registered as an instance, not captured.
    container.register(Database.self, instance: Database())
    container.register(Repository.self) { r in Repository(db: try r.resolve(Database.self)) }
}
