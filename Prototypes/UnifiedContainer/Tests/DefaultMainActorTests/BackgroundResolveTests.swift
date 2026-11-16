// What happens when code off the main actor resolves registrations made in a module
// with default main-actor isolation.
//
// Before `register` required `@Sendable` factories, a closure written here was a
// main-actor closure, and resolving it from a background task ran it off the main
// actor with no error. Now that code doesn't compile (see CompileChecks), and what
// does compile is safe to resolve from anywhere.

import Foundation
import Testing
import AstrojectUnified

/// Opted out of the module's default main-actor isolation.
nonisolated final class BackgroundService: Sendable {
    let id = UUID()
}

@Suite("Background resolving with default main-actor isolation")
struct BackgroundResolveTests {
    @Test("A plain register closure written in main-actor code runs on the resolving thread")
    func plainClosureRunsOffMain() async throws {
        let container = UnifiedContainer()
        container.register(Bool.self) { _ in Thread.isMainThread }
        let ranOnMain = try await Task.detached { try container.resolve(Bool.self) }.value
        #expect(ranOnMain == false)
    }

    @Test("A plain register closure, resolved on the main actor, still works")
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

    @Test("A nonisolated type resolves as one singleton from many tasks")
    func nonisolatedSingletonFromBackground() async throws {
        let container = UnifiedContainer()
        container.register(BackgroundService.self) { _ in BackgroundService() }.asSingleton()
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
