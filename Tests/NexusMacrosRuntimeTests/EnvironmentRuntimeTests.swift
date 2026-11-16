//
//  EnvironmentRuntimeTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
import AstrojectNexusMacros
import AstrojectSync

protocol MacroPuzzleSource: AnyObject {
    var label: String { get }
}

@Injectable(as: MacroPuzzleSource.self)
final class MacroRemotePuzzleSource: MacroPuzzleSource {
    let label = "remote"
    init() {}
}

@Injectable(as: MacroPuzzleSource.self, environments: [.debug, .test])
final class MacroStubPuzzleSource: MacroPuzzleSource {
    let label = "stub"
    init() {}
}

final class MacroDebugMenu {}

@Assembly(MacroRemotePuzzleSource.self, MacroStubPuzzleSource.self)
struct MacroPuzzleSourceAssembly {
    @Provides(name: "build")
    static func releaseBuild() -> String { "release" }

    @Provides(name: "build", environments: [.debug])
    static func debugBuild() -> String { "debug" }
}

@Assembly(environments: [.debug])
struct MacroDebugMenuAssembly {
    @Provides
    static func menu() -> MacroDebugMenu { MacroDebugMenu() }
}

@Suite("environments: at runtime")
struct EnvironmentRuntimeTests {
    func makeContainer(_ environment: AstrojectEnvironment?) throws -> SyncContainer {
        try SyncContainer(
            environment: environment,
            assemblies: [MacroPuzzleSourceAssembly(), MacroDebugMenuAssembly()]
        )
    }
    
    @Test("A type outside the environment isn't registered")
    func typeSkippedOutsideEnvironment() throws {
        let container = try makeContainer(.release)
        
        #expect(try container.resolve((any MacroPuzzleSource).self).label == "remote")
        #expect(!container.isRegistered(MacroStubPuzzleSource.self))
    }
    
    @Test("A type in the environment replaces the earlier one")
    func typeIncludedInEnvironment() throws {
        let container = try makeContainer(.test)
        
        #expect(try container.resolve((any MacroPuzzleSource).self).label == "stub")
    }
    
    @Test("@Provides follows the environment")
    func providesFollowsEnvironment() throws {
        #expect(try makeContainer(.release).resolve(String.self, name: "build") == "release")
        #expect(try makeContainer(.debug).resolve(String.self, name: "build") == "debug")
    }
    
    @Test("@Assembly(environments:) only runs in those environments")
    func assemblyFollowsEnvironment() throws {
        #expect(!(try makeContainer(.release)).isRegistered(MacroDebugMenu.self))
        #expect(try makeContainer(.debug).isRegistered(MacroDebugMenu.self))
    }
    
    @Test("Without an environment, everything is registered")
    func noEnvironmentRegistersEverything() throws {
        let container = try makeContainer(nil)
        
        #expect(try container.resolve((any MacroPuzzleSource).self).label == "stub")
        #expect(container.isRegistered(MacroDebugMenu.self))
        #expect(try container.resolve(String.self, name: "build") == "debug")
    }
}
