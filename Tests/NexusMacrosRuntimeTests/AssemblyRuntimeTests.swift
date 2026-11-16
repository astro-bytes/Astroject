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

final class MacroDecoder {
    let source: String
    init(source: String) { self.source = source }
}

final class MacroClient {
    let decoder: MacroDecoder
    init(decoder: MacroDecoder) { self.decoder = decoder }
}

@Assembly(MacroEngine.self)
struct MacroProvidesAssembly {
    @Provides(scope: .singleton)
    static func decoder() -> MacroDecoder {
        MacroDecoder(source: "first")
    }
    
    @Provides(name: "client")
    static func client(decoder: MacroDecoder) -> MacroClient {
        MacroClient(decoder: decoder)
    }
    
    @Provides(as: MacroGreeter.self)
    static func greeter() -> MacroEnglishGreeter {
        MacroEnglishGreeter()
    }
}

@Suite("@Provides at runtime")
struct ProvidesRuntimeTests {
    @Test("Registers providers with scope, name, as: and resolved parameters")
    func registersProviders() throws {
        let container = try SyncContainer(assemblies: [MacroProvidesAssembly()])
        
        let decoder = try container.resolve(MacroDecoder.self)
        let client = try container.resolve(MacroClient.self, name: "client")
        
        #expect(decoder === (try container.resolve(MacroDecoder.self)))
        #expect(client.decoder === decoder)
        #expect(try container.resolve(MacroGreeter.self).greeting == "hello")
        _ = try container.resolve(MacroEngine.self)
    }
    
    @Test("Providers register after the listed types, top to bottom")
    func providerOrder() throws {
        let container = try SyncContainer(assemblies: [MacroProvidesAssembly()])
        let keys = container.registrationReport().entries.map { String(describing: $0.key.productType) }
        
        #expect(keys.starts(with: ["MacroEngine", "MacroDecoder", "MacroClient", "MacroEnglishGreeter"]))
    }
}
