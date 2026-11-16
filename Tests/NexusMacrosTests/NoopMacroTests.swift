//
//  NoopMacroTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AstrojectNexusMacrosPlugin)
import AstrojectNexusMacrosPlugin

let testMacros: [String: Macro.Type] = [
    "Noop": NoopMacro.self
]
#endif

final class NoopMacroTests: XCTestCase {
    func testNoopExpandsToNothing() throws {
        #if canImport(AstrojectNexusMacrosPlugin)
        assertMacroExpansion(
            """
            @Noop
            final class Engine {}
            """,
            expandedSource: """
            final class Engine {}
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("Macros are only supported when running tests for the host platform")
        #endif
    }
}
