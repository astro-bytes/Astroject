//
//  NoopMacro.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// A peer macro that adds nothing.
///
/// It proves the plugin builds, loads and expands in tests and CI. It is not declared in
/// `AstrojectNexusMacros`, so apps can't use it. Remove it once real macros land.
public struct NoopMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
