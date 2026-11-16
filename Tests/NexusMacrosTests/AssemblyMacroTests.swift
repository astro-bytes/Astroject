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
