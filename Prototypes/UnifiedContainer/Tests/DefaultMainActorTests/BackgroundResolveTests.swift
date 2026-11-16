// What happens when code off the main actor resolves registrations made in a module
// with default main-actor isolation. Each risky case runs as an exit test (in its own
// process), so a crash shows up as a result instead of ending the whole test run.

import Foundation
import Testing
import AstrojectUnified

/// Main-actor state, like an app's shared settings. Main-actor by default in this module.
let sharedSettings = Settings()

/// Registers the way an app's assembly would. Main-actor by default in this module, so
/// the closures below are main-actor closures: the compiler lets them read `sharedSettings`.
func registerPlainClosures(on container: UnifiedContainer) {
    container.register(String.self) { _ in sharedSettings.theme }
    container.register(Bool.self) { _ in Thread.isMainThread }
}

/// Opted out of the module's default main-actor isolation.
nonisolated final class BackgroundService: Sendable {
    let id = UUID()
}

@Suite("Background resolving with default main-actor isolation")
struct BackgroundResolveTests {
    // Exit codes from the child process: 3 means the factory ran off the main thread
    // without trapping. A trap would show up as a signal instead.

    @Test("Plain register closure that reads main-actor state, resolved off the main actor")
    func mainActorStateFromBackground() async {
        await #expect(processExitsWith: .exitCode(3)) {
            let container = UnifiedContainer()
            await MainActor.run { registerPlainClosures(on: container) }
            let theme = await Task.detached { try? container.resolve(String.self) }.value
            exit(theme == "dark" ? 3 : 1)
        }
    }

    @Test("Plain register closure, resolved off the main actor, runs on a background thread")
    func plainClosureThread() async {
        await #expect(processExitsWith: .exitCode(3)) {
            let container = UnifiedContainer()
            await MainActor.run { registerPlainClosures(on: container) }
            let ranOnMain = await Task.detached { try? container.resolve(Bool.self) }.value
            exit(ranOnMain == false ? 3 : 1)
        }
    }

    @Test("Plain register closure, resolved on the main actor, still works")
    func plainClosureOnMain() throws {
        let container = UnifiedContainer()
        container.register(Int.self) { _ in 42 }
        #expect(try container.resolve(Int.self) == 42)
    }

    @Test("registerMainActor off the main actor throws instead of crashing")
    func registerMainActorFromBackground() async throws {
        let container = UnifiedContainer()
        container.registerMainActor(Settings.self) { _ in Settings() }
        let error = await Task.detached { () -> ContainerError? in
            do {
                _ = try container.resolve(Settings.self)
                return nil
            } catch let error as ContainerError {
                return error
            } catch {
                return nil
            }
        }.value
        #expect(error == .mainActorRequired("Settings"))
    }

    @Test("A @Sendable closure building a nonisolated type resolves off the main actor")
    func sendableClosureFromBackground() async throws {
        let container = UnifiedContainer()
        container.register(BackgroundService.self) { @Sendable _ in BackgroundService() }.asSingleton()
        let ids = try await withThrowingTaskGroup(of: UUID.self) { group in
            for _ in 0..<20 {
                group.addTask { try container.resolve(BackgroundService.self).id }
            }
            var ids = Set<UUID>()
            for try await id in group {
                ids.insert(id)
            }
            return ids
        }
        #expect(ids.count == 1)
    }
}
