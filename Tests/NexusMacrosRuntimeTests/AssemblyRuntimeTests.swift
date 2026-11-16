//
//  AssemblyRuntimeTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
import AstrojectNexusMacros
import AstrojectSync

protocol MacroGreeter: AnyObject {
    var greeting: String { get }
}

@Injectable(as: MacroGreeter.self)
final class MacroEnglishGreeter: MacroGreeter {
    let greeting = "hello"
    init() {}
}

@Injectable(as: MacroGreeter.self)
final class MacroSpanishGreeter: MacroGreeter {
    let greeting = "hola"
    init() {}
}

@Injectable(as: MacroGreeter.self)
final class MacroFrenchGreeter: MacroGreeter {
    let greeting = "bonjour"
    init() {}
}

@Assembly(MacroEnglishGreeter.self, MacroSpanishGreeter.self)
struct MacroGreetingAssembly {}

@Assembly(MacroFrenchGreeter.self, requires: [MacroGreetingAssembly.self])
struct MacroOverrideAssembly {}

@Suite("@Assembly at runtime")
struct AssemblyRuntimeTests {
    @Test("Registers listed types in order, so the last one wins")
    func listOrder() throws {
        let container = try SyncContainer(assemblies: [MacroGreetingAssembly()])
        
        #expect(try container.resolve(MacroGreeter.self).greeting == "hola")
        _ = try container.resolve(MacroEnglishGreeter.self)
    }
    
    @Test("Required assemblies run first, so the dependent wins")
    func requiresOrder() throws {
        let container = try SyncContainer(assemblies: [MacroOverrideAssembly()])
        
        #expect(try container.resolve(MacroGreeter.self).greeting == "bonjour")
        #expect(MacroOverrideAssembly.requiredAssemblies.count == 1)
    }
}
