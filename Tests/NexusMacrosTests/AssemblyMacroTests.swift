//
//  AssemblyMacroTests.swift
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

let assemblySpecs: [String: MacroSpec] = [
    "Assembly": MacroSpec(type: AssemblyMacro.self, conformances: ["Assembly"])
]
#endif

final class AssemblyMacroTests: XCTestCase {
    func testRegistersTypesInOrderWithRequirements() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(PuzzleViewModel.self, ScoreService.self, requires: [DataAssembly.self])
            struct PuzzleFeatureAssembly {}
            """,
            expandedSource: """
            struct PuzzleFeatureAssembly {}

            extension PuzzleFeatureAssembly: AstrojectCore.Assembly {
                static var requiredAssemblies: [any AstrojectCore.Assembly.Type] {
                    [DataAssembly.self]
                }

                func assemble(container: any AstrojectCore.Container) throws {
                    try PuzzleViewModel.register(in: container)
                    try ScoreService.register(in: container)
                }
            }
            """,
            macroSpecs: assemblySpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testPublicAssemblyWithoutRequirements() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(APIClient.self)
            public struct DataAssembly {}
            """,
            expandedSource: """
            public struct DataAssembly {}

            extension DataAssembly: AstrojectCore.Assembly {
                public func assemble(container: any AstrojectCore.Container) throws {
                    try APIClient.register(in: container)
                }
            }
            """,
            macroSpecs: assemblySpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testDuplicateTypeWarns() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(APIClient.self, APIClient.self)
            struct DataAssembly {}
            """,
            expandedSource: """
            struct DataAssembly {}

            extension DataAssembly: AstrojectCore.Assembly {
                func assemble(container: any AstrojectCore.Container) throws {
                    try APIClient.register(in: container)
                    try APIClient.register(in: container)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "APIClient is listed more than once; registration is last one wins, so only the last one takes effect",
                    line: 1,
                    column: 27,
                    severity: .warning
                )
            ],
            macroSpecs: assemblySpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testNonTypeArgumentIsAnError() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(APIClient())
            struct DataAssembly {}
            """,
            expandedSource: """
            struct DataAssembly {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Assembly takes types, such as UserService.self", line: 1, column: 11)
            ],
            macroSpecs: assemblySpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}

#if canImport(AstrojectNexusMacrosPlugin)
let providesSpecs: [String: MacroSpec] = [
    "Assembly": MacroSpec(type: AssemblyMacro.self, conformances: ["Assembly"]),
    "Provides": MacroSpec(type: ProvidesMacro.self)
]
#endif

final class ProvidesMacroTests: XCTestCase {
    func testProvidersRegisterAfterListedTypesTopToBottom() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly(APIClient.self)
            struct DataAssembly {
                @Provides(scope: .singleton)
                static func session() -> URLSession {
                    URLSession.shared
                }

                @Provides(name: "analytics", as: AnyLogger.self)
                static func analyticsLogger(session: URLSession) async -> Logger {
                    Logger(session: session)
                }
            }
            """,
            expandedSource: """
            struct DataAssembly {
                static func session() -> URLSession {
                    URLSession.shared
                }

                static func analyticsLogger(session: URLSession) async -> Logger {
                    Logger(session: session)
                }
            }

            extension DataAssembly: AstrojectCore.Assembly {
                func assemble(container: any AstrojectCore.Container) throws {
                    try APIClient.register(in: container)
                    try container.register(URLSession.self, initializer: Self.session, fileID: "TestModule/test.swift", line: 3).asSingleton()
                    _ = { (instance: Logger) -> AnyLogger in
                        instance
                    }
                    try container.register(Logger.self, name: "analytics", initializer: Self.analyticsLogger(session:), fileID: "TestModule/test.swift", line: 8).implements(AnyLogger.self)
                }
            }
            """,
            macroSpecs: providesSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testDuplicateProviderWarns() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly
            struct DataAssembly {
                @Provides
                static func first() -> Decoder { Decoder() }
                @Provides
                static func second() -> Decoder { Decoder() }
            }
            """,
            expandedSource: """
            struct DataAssembly {
                static func first() -> Decoder { Decoder() }
                static func second() -> Decoder { Decoder() }
            }

            extension DataAssembly: AstrojectCore.Assembly {
                func assemble(container: any AstrojectCore.Container) throws {
                    try container.register(Decoder.self, initializer: Self.first, fileID: "TestModule/test.swift", line: 3)
                    try container.register(Decoder.self, initializer: Self.second, fileID: "TestModule/test.swift", line: 5)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Decoder is already provided in this assembly; registration is last one wins, so this replaces it",
                    line: 5,
                    column: 5,
                    severity: .warning
                )
            ],
            macroSpecs: providesSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testProvidesMustBeStatic() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Assembly
            struct DataAssembly {
                @Provides
                func decoder() -> Decoder { Decoder() }
            }
            """,
            expandedSource: """
            struct DataAssembly {
                func decoder() -> Decoder { Decoder() }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Provides functions must be static", line: 4, column: 10)
            ],
            macroSpecs: providesSpecs
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
