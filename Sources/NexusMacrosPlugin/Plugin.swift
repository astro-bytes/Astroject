//
//  Plugin.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler plugin that provides the Nexus macros.
@main
struct AstrojectNexusMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
        InjectableInitMacro.self,
        AssemblyMacro.self
    ]
}
