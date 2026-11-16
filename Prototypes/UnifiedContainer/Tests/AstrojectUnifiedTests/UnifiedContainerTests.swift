import Foundation
import Testing
@testable import AstrojectUnified

@Suite("Sync graph")
struct SyncGraphTests {
    @Test("Transient makes a new instance each time")
    func transient() throws {
        let container = UnifiedContainer()
        container.register(Logger.self) { _ in Logger() }
        let first = try container.resolve(Logger.self)
        let second = try container.resolve(Logger.self)
        #expect(first !== second)
    }

    @Test("Singleton returns the same instance")
    func singleton() throws {
        let container = UnifiedContainer()
        container.register(Logger.self) { _ in Logger() }.asSingleton()
        #expect(try container.resolve(Logger.self) === container.resolve(Logger.self))
    }

    @Test("Names keep registrations apart")
    func names() throws {
        let container = UnifiedContainer()
        container.register(String.self, name: "a") { _ in "A" }
        container.register(String.self, name: "b") { _ in "B" }
        #expect(try container.resolve(String.self, name: "a") == "A")
        #expect(try container.resolve(String.self, name: "b") == "B")
    }

    @Test("Last registration wins")
    func lastWins() throws {
        let container = UnifiedContainer()
        container.register(Int.self) { _ in 1 }
        container.register(Int.self) { _ in 2 }
        #expect(try container.resolve(Int.self) == 2)
    }

    @Test("Missing registration throws")
    func missing() {
        let container = UnifiedContainer()
        #expect(throws: ContainerError.noRegistration("Int")) {
            try container.resolve(Int.self)
        }
    }

    @Test("Cycles are detected")
    func cycle() {
        let container = UnifiedContainer()
        container.register(CycleA.self) { r in CycleA(b: try r.resolve(CycleB.self)) }
        container.register(CycleB.self) { r in CycleB(a: try r.resolve(CycleA.self)) }
        #expect(throws: ContainerError.cyclicDependency(["CycleA", "CycleB", "CycleA"])) {
            try container.resolve(CycleA.self)
        }
    }

    @Test("Concurrent resolves of one type never report a false cycle")
    func concurrentResolves() async throws {
        let container = UnifiedContainer()
        container.register(Logger.self) { _ in Logger() }.asSingleton()
        container.register(Int.self) { _ in 42 }

        let ids = try await withThrowingTaskGroup(of: UUID.self) { group in
            for _ in 0..<200 {
                group.addTask {
                    #expect(try container.resolve(Int.self) == 42)
                    return try container.resolve(Logger.self).id
                }
            }
            return try await group.reduce(into: Set<UUID>()) { $0.insert($1) }
        }
        #expect(ids.count == 1)
    }

    @Test("An actor is built by a normal sync factory")
    func actors() async throws {
        let container = UnifiedContainer()
        container.register(ImageCache.self) { _ in ImageCache() }.asSingleton()

        let total = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    let cache = try container.resolve(ImageCache.self)
                    return await cache.hit()
                }
            }
            return try await group.reduce(0) { max($0, $1) }
        }
        #expect(total == 50)
    }
}

@Suite("Async setup")
struct AsyncSetupTests {
    @Test("Setup awaits, then the graph resolves synchronously")
    func asyncSetup() async throws {
        let container = try await UnifiedContainer(assemblies: [DataAssembly(), LoggingAssembly()])
        let first = try container.resolve(Repository.self)
        let second = try container.resolve(Repository.self)
        #expect(first !== second)
        #expect(first.db === second.db)
    }

    @Test("The sync initializer refuses assemblies that need setup, every time")
    func syncInitRefusesSetup() throws {
        for _ in 0..<3 {
            #expect(throws: ContainerError.asyncSetupRequired(["DataAssembly"])) {
                _ = try UnifiedContainer(assemblies: [LoggingAssembly(), DataAssembly()])
            }
        }
    }

    @Test("The sync initializer works when nothing needs setup")
    func syncInit() throws {
        let container = try UnifiedContainer(assemblies: [LoggingAssembly()])
        _ = try container.resolve(Logger.self)
    }
}

@Suite("Async providers")
struct AsyncProviderTests {
    func makeContainer() -> UnifiedContainer {
        let container = UnifiedContainer()
        container.register(Database.self, instance: Database())
        container.registerProvider(Report.self) { r in
            try await Report(db: try r.resolve(Database.self))
        }
        return container
    }

    @Test("A provider is resolved synchronously and awaited later")
    func transientProvider() async throws {
        let container = makeContainer()
        let makeReport = try container.resolve(AsyncProvider<Report>.self)
        let first = try await makeReport()
        let second = try await makeReport()
        #expect(first.id != second.id)
        #expect(first.db === second.db)
    }

    @Test("Resolving the product itself says to use the provider")
    func resolvingProductThrows() {
        let container = makeContainer()
        #expect(throws: ContainerError.registeredAsProvider("Report")) {
            try container.resolve(Report.self)
        }
    }

    @Test("A sync factory can depend on a provider without becoming async")
    func dependsOnProvider() async throws {
        final class ReportScreen {
            let makeReport: AsyncProvider<Report>
            init(makeReport: AsyncProvider<Report>) { self.makeReport = makeReport }
        }
        let container = makeContainer()
        container.register(ReportScreen.self) { r in
            ReportScreen(makeReport: try r.resolve(AsyncProvider<Report>.self))
        }
        let screen = try container.resolve(ReportScreen.self)
        _ = try await screen.makeReport()
    }

    @Test("A singleton provider creates once, even with concurrent first calls")
    func singletonProvider() async throws {
        let counter = Counter()
        let container = UnifiedContainer()
        container.registerProvider(RemoteConfig.self) { _ in
            try await RemoteConfig(counter: counter)
        }.asSingleton()

        let makeConfig = try container.resolve(AsyncProvider<RemoteConfig>.self)
        let ids = try await withThrowingTaskGroup(of: UUID.self) { group in
            for _ in 0..<20 {
                group.addTask { try await makeConfig().id }
            }
            return try await group.reduce(into: Set<UUID>()) { $0.insert($1) }
        }
        #expect(ids.count == 1)
        #expect(counter.count == 1)
    }
}

@Suite("Main actor")
struct MainActorTests {
    func makeContainer() -> UnifiedContainer {
        let container = UnifiedContainer()
        container.register(Database.self, instance: Database())
        container.register(Repository.self) { r in Repository(db: try r.resolve(Database.self)) }
        container.register(Logger.self) { _ in Logger() }.asSingleton()
        container.registerMainActor(ProfileViewModel.self) { r in
            ProfileViewModel(repository: try r.resolve(Repository.self), logger: try r.resolve(Logger.self))
        }
        container.registerMainActor(ProfileScreenModel.self) { r in
            ProfileScreenModel(profile: try r.resolve(ProfileViewModel.self))
        }
        return container
    }

    @Test("Main-actor code resolves main-actor types synchronously")
    @MainActor
    func resolveOnMain() throws {
        let container = makeContainer()
        let screen = try container.main.resolve(ProfileScreenModel.self)
        let logger = try container.resolve(Logger.self)
        #expect(screen.profile.logger === logger)
    }

    @Test("Off the main actor, a main-actor type always throws")
    func resolveOffMain() async throws {
        let container = makeContainer()
        // Create the instances once on the main actor first, to show caching doesn't change the answer.
        await MainActor.run { _ = try? container.main.resolve(ProfileViewModel.self) }
        #expect(throws: ContainerError.mainActorRequired("ProfileViewModel")) {
            try container.resolve(ProfileViewModel.self)
        }
    }

    @Test("Off-main code hops to the main actor to get one")
    func hopToMain() async throws {
        let container = makeContainer()
        let ok = try await MainActor.run {
            let viewModel = try container.main.resolve(ProfileViewModel.self)
            let db = try container.resolve(Database.self)
            return viewModel.repository.db === db
        }
        #expect(ok)
    }
}
