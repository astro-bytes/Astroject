//
//  RegistrationReportTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
@testable import AstrojectCore
@testable import AstrojectAsync

struct AsyncReportDataAssembly: Assembly {
    static let line: UInt = #line + 2
    func assemble(container: Container) throws {
        try container.register(Int.self) { 1 }
    }
}

struct AsyncReportMocksAssembly: Assembly {
    static var requiredAssemblies: [Assembly.Type] { [AsyncReportDataAssembly.self] }
    static let line: UInt = #line + 2
    func assemble(container: Container) throws {
        try container.register(Int.self) { 2 }
    }
}

@Suite("Registration Report: AsyncContainer")
struct AsyncRegistrationReportTests {
    @Test("Reports a Two-Assembly Override")
    func reportsTwoAssemblyOverride() async throws {
        let container = AsyncContainer()
        let assembler = Assembler(container: container)
        assembler.logsOverrides = false
        try assembler.add(assembly: AsyncReportMocksAssembly()).assemble()
        
        let entry = try #require(container.registrationReport().overridden.first)
        #expect(entry.sources == [
            RegistrationSource(
                assembly: "AsyncReportDataAssembly",
                fileID: "AsyncTests/RegistrationReportTests.swift",
                line: AsyncReportDataAssembly.line
            ),
            RegistrationSource(
                assembly: "AsyncReportMocksAssembly",
                fileID: "AsyncTests/RegistrationReportTests.swift",
                line: AsyncReportMocksAssembly.line
            )
        ])
        #expect(try await container.resolve(Int.self) == 2)
    }
}
