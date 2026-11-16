// Default main-actor isolation. A main-actor type built by a plain register closure.
import AstrojectUnified

final class Settings {
    var theme = "dark"
}

func assemble(_ container: UnifiedContainer) {
    container.register(Settings.self) { _ in Settings() }
}
