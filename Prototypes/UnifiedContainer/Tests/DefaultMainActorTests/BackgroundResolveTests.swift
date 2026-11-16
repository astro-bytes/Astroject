// What happens when code off the main actor resolves registrations made in a module
// with default main-actor isolation. Each risky case runs as an exit test (in its own
// process), so a crash shows up as a result instead of ending the whole test run.

import Foundation
import Testing
import AstrojectUnified

/// Opted out of the module's default main-actor isolation.
nonisolated final class BackgroundService: Sendable {
    let id = UUID()
}

@Suite("Background resolving with default main-actor isolation")
struct BackgroundResolveTests {
    @Test("Plain register closure that builds a main-actor type, resolved off the main actor")
    func mainActorTypeFromBackground() async {
        await #expect(processExitsWith: .failure) {
            let container = UnifiedContainer()
            container.register(Settings.self) { _ in Settings() }
            await Task.detached {
                _ = try? container.resolve(Settings.self)
            }.value
        }
    }

    @Test("Plain register closure that touches no main-actor state, resolved off the main actor")
    func trivialClosureFromBackground() async {
        await #expect(processExitsWith: .failure) {
            let container = UnifiedContainer()
            container.register(Int.self) { _ in 42 }
            await Task.detached {
                _ = try? container.resolve(Int.self)
            }.value
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
