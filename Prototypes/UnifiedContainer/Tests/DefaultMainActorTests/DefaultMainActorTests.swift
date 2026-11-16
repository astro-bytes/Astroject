// Compiled with `.defaultIsolation(MainActor.self)`, like a new Xcode 26 app target.
// Every type and function here is @MainActor unless marked otherwise, and none of
// the app code below says anything about isolation.

import Foundation
import Testing
import AstrojectUnified

final class Settings {
    var theme = "dark"
}

final class SettingsStore {
    let settings: Settings
    init(settings: Settings) { self.settings = settings }
}

final class SettingsViewModel {
    let store: SettingsStore
    init(store: SettingsStore) { self.store = store }
}

final class Session {
    let token: String
    init(token: String) async {
        self.token = token
    }
}

struct AppAssembly: Assembly {
    func assemble(container: UnifiedContainer) throws {
        container.register(Settings.self, instance: Settings())
        container.registerMainActor(SettingsStore.self) { r in
            SettingsStore(settings: try r.resolve(Settings.self))
        }.asSingleton()
        container.registerMainActor(SettingsViewModel.self) { r in
            SettingsViewModel(store: try r.resolve(SettingsStore.self))
        }
        container.registerProvider(Session.self) { _ in
            await Session(token: "abc")
        }
    }
}

@Suite("Default main-actor isolation")
struct DefaultMainActorTests {
    @Test("Main-actor app types resolve through container.main")
    func resolve() throws {
        let container = try UnifiedContainer(assemblies: [AppAssembly()])
        let first = try container.main.resolve(SettingsViewModel.self)
        let second = try container.main.resolve(SettingsViewModel.self)
        #expect(first !== second)
        #expect(first.store === second.store)
        #expect(first.store.settings.theme == "dark")
    }

    @Test("A plain register closure works for a value created up front")
    func plainRegister() throws {
        let container = UnifiedContainer()
        container.register(Settings.self) { _ in Settings() }
        #expect(try container.main.resolve(Settings.self).theme == "dark")
    }

    @Test("Providers work for main-actor types with async inits")
    func provider() async throws {
        // In async code, Swift picks the async initializer, so this needs `await`.
        let container = try await UnifiedContainer(assemblies: [AppAssembly()])
        let makeSession = try container.main.resolve(AsyncProvider<Session>.self)
        let session = try await makeSession()
        #expect(session.token == "abc")
    }
}
