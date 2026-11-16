//
//  InjectableMacroTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AstrojectNexusMacrosPlugin)
import AstrojectNexusMacrosPlugin

let injectableSpecs: [String: MacroSpec] = [
    "Injectable": MacroSpec(type: InjectableMacro.self, conformances: ["Injectable"]),
    "InjectableInit": MacroSpec(type: InjectableInitMacro.self)
]
#endif

final class InjectableMacroTests: XCTestCase {
    func testDefaultScopeUsesInitializerName() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class Car {
                init(engine: Engine, wheels: Wheels) {}
            }
            """,
            expandedSource: """
            final class Car {
                init(engine: Engine, wheels: Wheels) {}
            }

            extension Car: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Car.self, initializer: Car.init(engine:wheels:), fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testScopeNameAndPublicAccess() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable(scope: .singleton, name: "primary")
            public final class PuzzleRepository {
                public init(_ api: API) {}
            }
            """,
            expandedSource: """
            public final class PuzzleRepository {
                public init(_ api: API) {}
            }

            extension PuzzleRepository: AstrojectNexus.Injectable {
                public static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(PuzzleRepository.self, name: "primary", initializer: PuzzleRepository.init(_:), fileID: "TestModule/test.swift", line: 1).asSingleton()
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testTransientWeakAndGraphScopes() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        for (scope, call) in [("transient", ".asTransient()"), ("weak", ".asWeak()"), ("graph", "")] {
            assertMacroExpansion(
                """
                @Injectable(scope: .\(scope))
                final class Engine {
                    init(fuel: Fuel) {}
                }
                """,
                expandedSource: """
                final class Engine {
                    init(fuel: Fuel) {}
                }

                extension Engine: AstrojectNexus.Injectable {
                    static func register(in container: any AstrojectCore.Container) throws {
                        try container.register(Engine.self, initializer: Engine.init(fuel:), fileID: "TestModule/test.swift", line: 1)\(call)
                    }
                }
                """,
                macroSpecs: injectableSpecs
            )
        }
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAsyncThrowingInitializerWithoutParameters() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class Database {
                init() async throws {}
            }
            """,
            expandedSource: """
            final class Database {
                init() async throws {}
            }

            extension Database: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Database.self, initializer: {
                            try await Database()
                        }, fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testMarkedInitializerIsUsed() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            struct Settings {
                init() {}
                @InjectableInit
                init(store: Store) {}
            }
            """,
            expandedSource: """
            struct Settings {
                init() {}
                init(store: Store) {}
            }

            extension Settings: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Settings.self, initializer: Settings.init(store:), fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructUsesMemberwiseInitializer() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            struct Garage {
                static let shared = 1
                let engine: Engine
                let label = "garage"
                var wheels: Wheels
                var count: Int { 4 }
            }
            """,
            expandedSource: """
            struct Garage {
                static let shared = 1
                let engine: Engine
                let label = "garage"
                var wheels: Wheels
                var count: Int { 4 }
            }

            extension Garage: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Garage.self, initializer: Garage.init(engine:wheels:), fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testSeveralInitializersWithoutMarkIsAnError() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class Car {
                init() {}
                init(engine: Engine) {}
            }
            """,
            expandedSource: """
            final class Car {
                init() {}
                init(engine: Engine) {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Injectable needs to know which initializer to use; mark one with @InjectableInit",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Mark 'init()' with @InjectableInit"),
                        FixItSpec(message: "Mark 'init(engine:)' with @InjectableInit")
                    ]
                )
            ],
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testEnumIsAnError() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            enum Mode {}
            """,
            expandedSource: """
            enum Mode {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Injectable can only be applied to a class or struct", line: 1, column: 1)
            ],
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testFailableInitializerIsAnError() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class Token {
                init?(raw: String) {}
            }
            """,
            expandedSource: """
            final class Token {
                init?(raw: String) {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Injectable can't use a failable initializer", line: 3, column: 5)
            ],
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAsForwardsEachTypeAndChecksConformance() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable(scope: .singleton, as: Repository.self, Cache.self)
            final class RemoteRepository: Repository, Cache {
                init(api: API) {}
            }
            """,
            expandedSource: """
            final class RemoteRepository: Repository, Cache {
                init(api: API) {}
            }

            extension RemoteRepository: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    _ = { (instance: RemoteRepository) -> Repository in
                        instance
                    }
                    _ = { (instance: RemoteRepository) -> Cache in
                        instance
                    }
                    try container.register(RemoteRepository.self, initializer: RemoteRepository.init(api:), fileID: "TestModule/test.swift", line: 1).asSingleton().implements(Repository.self).implements(Cache.self)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAsRequiresTypes() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable(as: "Repository")
            final class RemoteRepository {
                init() {}
            }
            """,
            expandedSource: """
            final class RemoteRepository {
                init() {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "as: takes types, such as PuzzleRepositoryProtocol.self", line: 1, column: 17)
            ],
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testNamedParameterIsResolvedByName() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class Analytics {
                init(@Named("analytics") logger: Logger, session: Session) {}
            }
            """,
            expandedSource: """
            final class Analytics {
                init(@Named("analytics") logger: Logger, session: Session) {}
            }

            extension Analytics: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Analytics.self, resolveSync: { resolver in
                            try Analytics(logger: resolver.resolve(Logger.self, name: "analytics"), session: resolver.resolve(Session.self))
                        }, resolveAsync: { resolver in
                            try await Analytics(logger: resolver.resolve(Logger.self, name: "analytics"), session: resolver.resolve(Session.self))
                        }, fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testArgumentsGenerateFactory() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            final class PuzzleViewModel {
                init(@Argument puzzleID: String, @Argument _ difficulty: Difficulty, repository: Repository) {}
            }
            """,
            expandedSource: """
            final class PuzzleViewModel {
                init(@Argument puzzleID: String, @Argument _ difficulty: Difficulty, repository: Repository) {}
            }

            extension PuzzleViewModel: AstrojectNexus.Injectable {
                /// Makes `PuzzleViewModel` from its `@Argument` values, resolving everything else.
                struct Factory {
                    let resolver: any AstrojectCore.Resolver

                    init(resolver: any AstrojectCore.Resolver) {
                        self.resolver = resolver
                    }

                    func make(puzzleID: String, _ difficulty: Difficulty) throws -> PuzzleViewModel {
                        try PuzzleViewModel(puzzleID: puzzleID, difficulty, repository: resolver.resolve(Repository.self))
                    }

                    func make(puzzleID: String, _ difficulty: Difficulty) async throws -> PuzzleViewModel {
                        try await PuzzleViewModel(puzzleID: puzzleID, difficulty, repository: resolver.resolve(Repository.self))
                    }
                }

                static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Factory.self, resolveSync: { resolver in
                            Factory(resolver: resolver)
                        }, resolveAsync: { resolver in
                            Factory(resolver: resolver)
                        }, fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAsyncInitializerFactoryOnlyMakesAsynchronously() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable
            public final class Loader {
                public init(@Argument path: String) async throws {}
            }
            """,
            expandedSource: """
            public final class Loader {
                public init(@Argument path: String) async throws {}
            }

            extension Loader: AstrojectNexus.Injectable {
                /// Makes `Loader` from its `@Argument` values, resolving everything else.
                public struct Factory {
                    public let resolver: any AstrojectCore.Resolver

                    public init(resolver: any AstrojectCore.Resolver) {
                        self.resolver = resolver
                    }

                    public func make(path: String) async throws -> Loader {
                        try await Loader(path: path)
                    }
                }

                public static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(Factory.self, resolveSync: { resolver in
                            Factory(resolver: resolver)
                        }, resolveAsync: { resolver in
                            Factory(resolver: resolver)
                        }, fileID: "TestModule/test.swift", line: 1)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAsWithArgumentsIsAnError() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable(as: Loading.self)
            final class Loader: Loading {
                init(@Argument path: String) {}
            }
            """,
            expandedSource: """
            final class Loader: Loading {
                init(@Argument path: String) {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "as: can't be used with @Argument parameters; the type is made through its Factory instead",
                    line: 1,
                    column: 1
                )
            ],
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
