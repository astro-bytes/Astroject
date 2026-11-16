// Default main-actor isolation. Before @Sendable factories, this compiled and raced
// when resolved off the main actor.
import AstrojectUnified

final class Settings {
    var theme = "dark"
}

let sharedSettings = Settings()

func assemble(_ container: UnifiedContainer) {
    container.register(String.self) { _ in sharedSettings.theme }
}
