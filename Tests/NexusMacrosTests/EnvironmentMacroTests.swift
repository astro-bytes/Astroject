//
//  EnvironmentMacroTests.swift
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
#endif

final class EnvironmentMacroTests: XCTestCase {
    func testInjectableSkipsRegistrationOutsideEnvironments() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Injectable(as: Repository.self, environments: [.debug, .test])
            final class StubRepository: Repository {
                init(api: API) {}
            }
            """,
            expandedSource: """
            final class StubRepository: Repository {
                init(api: API) {}
            }

            extension StubRepository: AstrojectNexus.Injectable {
                static func register(in container: any AstrojectCore.Container) throws {
                    guard AstrojectCore.AstrojectEnvironment.includes([.debug, .test]) else {
                        return
                    }
                    _ = { (instance: StubRepository) -> Repository in
                        instance
                    }
                    try container.register(StubRepository.self, initializer: StubRepository.init(api:), fileID: "TestModule/test.swift", line: 1).implements(Repository.self)
                }
            }
            """,
            macroSpecs: injectableSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testAssemblyAndProvidesEnvironments() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(DebugMenu.self, environments: [.debug])
            struct DebugAssembly {
                @Provides(scope: .singleton, environments: [.test])
                static func logger() -> Logger {
                    Logger()
                }
            }
            """,
            expandedSource: """
            struct DebugAssembly {
                static func logger() -> Logger {
                    Logger()
                }
            }

            extension DebugAssembly: AstrojectCore.Assembly {
                static var environments: Set<AstrojectCore.AstrojectEnvironment>? {
                    [.debug]
                }

                func assemble(container: any AstrojectCore.Container) throws {
                    try DebugMenu.register(in: container)
                    if AstrojectCore.AstrojectEnvironment.includes([.test]) {
                        try container.register(Logger.self, initializer: Self.logger, fileID: "TestModule/test.swift", line: 3).asSingleton()
                    }
                }
            }
            """,
            macroSpecs: providesSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }

    func testProvidersInDifferentEnvironmentsDontWarn() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly
            struct LoggingAssembly {
                @Provides(environments: [.release])
                static func logger() -> Logger {
                    Logger()
                }
                @Provides(environments: [.debug])
                static func verboseLogger() -> Logger {
                    Logger()
                }
            }
            """,
            expandedSource: """
            struct LoggingAssembly {
                static func logger() -> Logger {
                    Logger()
                }
                static func verboseLogger() -> Logger {
                    Logger()
                }
            }

            extension LoggingAssembly: AstrojectCore.Assembly {
                func assemble(container: any AstrojectCore.Container) throws {
                    if AstrojectCore.AstrojectEnvironment.includes([.release]) {
                        try container.register(Logger.self, initializer: Self.logger, fileID: "TestModule/test.swift", line: 3)
                    }
                    if AstrojectCore.AstrojectEnvironment.includes([.debug]) {
                        try container.register(Logger.self, initializer: Self.verboseLogger, fileID: "TestModule/test.swift", line: 7)
                    }
                }
            }
            """,
            macroSpecs: providesSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
