//
//  InjectRuntimeTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
import AstrojectNexusMacros
import AstrojectSync

final class MacroUserDefaults {
    let suite: String
    
    init(suite: String) {
        self.suite = suite
    }
}

@Injectable
final class MacroSettingsScreen {
    @Inject var engine: MacroEngine!
    @Inject(name: "app") var defaults: MacroUserDefaults?
    var title = "Settings"
    
    init(title: String) {
        self.title = title
    }
    
    init() {}
}

@Injectable
struct MacroScreenState {
    @Inject var wheels: MacroWheels!
}

@Suite("@Inject at runtime")
struct InjectRuntimeTests {
    func makeContainer() throws -> SyncContainer {
        let container = SyncContainer()
        try container.register(injectables: [MacroEngine.self, MacroWheels.self])
        try container.register(MacroUserDefaults.self, name: "app", factory: Factory(.sync { _ in
            MacroUserDefaults(suite: "app")
        }))
        return container
    }
    
    @Test("inject(from:) fills every marked property, including named ones")
    func fillsMarkedProperties() throws {
        let container = try makeContainer()
        let screen = MacroSettingsScreen(title: "Account")
        
        try screen.inject(from: container)
        
        #expect(screen.engine != nil)
        #expect(screen.defaults?.suite == "app")
        #expect(screen.title == "Account")
    }
    
    @Test("inject(from:) on a struct is mutating")
    func fillsStruct() throws {
        let container = try makeContainer()
        var state = MacroScreenState()
        
        try state.inject(from: container)
        
        #expect(state.wheels === (try container.resolve(MacroWheels.self)))
    }
    
    @Test("inject(from:) throws when a property can't be resolved")
    func throwsWhenUnresolvable() throws {
        let screen = MacroSettingsScreen()
        
        #expect(throws: (any Error).self) {
            try screen.inject(from: SyncContainer())
        }
    }
}
