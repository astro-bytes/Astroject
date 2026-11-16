//
//  RegistrationReportTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
@testable import AstrojectCore
@testable import AstrojectSync

struct ReportDataAssembly: Assembly {
    static let line: UInt = #line + 2
    func assemble(container: Container) throws {
        try container.register(Int.self) { 1 }
        try container.register(String.self) { "data" }
    }
}

struct ReportMocksAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [ReportDataAssembly.self] }
    static let line: UInt = #line + 2
    func assemble(container: Container) throws {
        try container.register(Int.self) { 2 }
    }
}

@Suite("Registration Report: SyncContainer")
struct SyncRegistrationReportTests {
    @Test("Reports a Two-Assembly Override")
    func reportsTwoAssemblyOverride() throws {
        let container = SyncContainer()
        let assembler = Assembler(container: container)
        assembler.logsOverrides = false
        try assembler.add(assembly: ReportMocksAssembly()).assemble()
        
        let report = container.registrationReport()
        let intKey = RegistrationKey(factoryType: Factory<Int, Resolver>.SyncBlock.self, productType: Int.self)
        
        #expect(report.entries.count == 2)
        #expect(report.overridden.map(\.key) == [intKey])
        
        let sources = try #require(report.overridden.first).sources
        #expect(sources == [
            RegistrationSource(
                assembly: "ReportDataAssembly",
                fileID: "SyncTests/RegistrationReportTests.swift",
                line: ReportDataAssembly.line
            ),
            RegistrationSource(
                assembly: "ReportMocksAssembly",
                fileID: "SyncTests/RegistrationReportTests.swift",
                line: ReportMocksAssembly.line
            )
        ])
        #expect(try container.resolve(Int.self) == 2)
        
        let expected = """
        Astroject: 2 keys registered, 1 overridden
        Int
          ├─ ReportDataAssembly    RegistrationReportTests.swift:\(ReportDataAssembly.line)
          └─ ReportMocksAssembly   RegistrationReportTests.swift:\(ReportMocksAssembly.line)   ← wins
        """
        #expect(report.formatted() == expected)
    }
    
    @Test("Records Registrations Without an Assembler")
    func recordsWithoutAssembler() throws {
        let container = SyncContainer()
        let line: UInt = #line + 1
        try container.register(Int.self, argumentType: String.self) { (arg: String) in arg.count }
        
        let entry = try #require(container.registrationReport().entries.first)
        #expect(entry.sources == [
            RegistrationSource(fileID: "SyncTests/RegistrationReportTests.swift", line: line)
        ])
    }
    
    @Test("Records Forwarding")
    func recordsForwarding() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 1 }
            .implements(CustomStringConvertible.self)
        
        let report = container.registrationReport()
        #expect(report.entries.count == 2)
        #expect(report.entries[1].sources == [RegistrationSource(forwardedFrom: "Int")])
    }
    
    @Test("Clear Resets the Report")
    func clearResetsReport() throws {
        let container = SyncContainer()
        try container.register(Int.self) { 1 }
        container.clear()
        
        #expect(container.registrationReport().entries.isEmpty)
    }
}
