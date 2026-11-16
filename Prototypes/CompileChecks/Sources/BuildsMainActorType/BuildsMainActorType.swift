// Default main-actor isolation. A plain register closure calling a main-actor init.
// (A synthesized init, like `Settings()` in Allowed, is nonisolated and compiles.)
import AstrojectUnified

final class Settings {
    var theme: String
    init(theme: String) { self.theme = theme }
}

func assemble(_ container: UnifiedContainer) {
    container.register(Settings.self) { _ in Settings(theme: "dark") }
}
