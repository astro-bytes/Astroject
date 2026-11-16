//
//  RegistrationReportTests.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Testing
@testable import AstrojectCore

protocol ReportRepository {}

@Suite("Registration Report")
struct RegistrationReportTests {
    let repositoryKey = RegistrationKey(
        factoryType: Factory<ReportRepository, Resolver>.SyncBlock.self,
        productType: ReportRepository.self
    )
    let namedKey = RegistrationKey(
        factoryType: Factory<Int, (Resolver, String)>.SyncBlock.self,
        productType: Int.self,
        argumentType: String.self,
        name: "count"
    )
    
    @Test("Formats Overridden Keys as a Tree")
    func formatsOverriddenKeys() {
        let report = RegistrationReport(entries: [
            .init(key: repositoryKey, sources: [
                RegistrationSource(assembly: "DataAssembly", fileID: "App/DataAssembly.swift", line: 12),
                RegistrationSource(assembly: "TestMocksAssembly", fileID: "AppTests/TestMocksAssembly.swift", line: 4)
            ]),
            .init(key: namedKey, sources: [
                RegistrationSource(fileID: "App/AppDelegate.swift", line: 30)
            ])
        ])
        
        let expected = """
        Astroject: 2 keys registered, 1 overridden
        ReportRepository
          ├─ DataAssembly        DataAssembly.swift:12
          └─ TestMocksAssembly   TestMocksAssembly.swift:4   ← wins
        """
        #expect(report.formatted() == expected)
    }
    
    @Test("Formats Every Key With Names, Arguments, and Forwarding")
    func formatsEveryKey() {
        let report = RegistrationReport(entries: [
            .init(key: namedKey, sources: [
                RegistrationSource(fileID: "App/AppDelegate.swift", line: 30)
            ]),
            .init(key: repositoryKey, sources: [
                RegistrationSource(assembly: "DataAssembly", forwardedFrom: "RemoteRepository")
            ])
        ])
        
        let expected = """
        Astroject: 2 keys registered, 0 overridden
        Int (name: "count", argument: String)
          └─ -              AppDelegate.swift:30
        ReportRepository
          └─ DataAssembly   forwarded from RemoteRepository
        """
        #expect(report.formatted(onlyOverridden: false) == expected)
    }
    
    @Test("Recorder Groups Registrations by Key in Order")
    func recorderGroupsByKey() {
        let recorder = RegistrationRecorder()
        let first = RegistrationSource(assembly: "A")
        let second = RegistrationSource(assembly: "B")
        let other = RegistrationSource(assembly: "C")
        
        recorder.record(repositoryKey, source: first)
        recorder.record(namedKey, source: other)
        recorder.record(repositoryKey, source: second)
        
        let report = recorder.report()
        #expect(report.entries.map(\.key) == [repositoryKey, namedKey])
        #expect(report.entries[0].sources == [first, second])
        #expect(report.entries[0].winner == second)
        #expect(report.overridden.map(\.key) == [repositoryKey])
        
        recorder.reset()
        #expect(recorder.report().entries.isEmpty)
    }
    
    @Test("Outermost Call Site Is Kept")
    func outermostCallSiteIsKept() {
        let source = RegistrationSource.withCallSite(fileID: "App/Outer.swift", line: 1) {
            RegistrationSource.withCallSite(fileID: "Lib/Inner.swift", line: 2) {
                RegistrationSource.$currentAssembly.withValue("SomeAssembly") {
                    RegistrationSource.current
                }
            }
        }
        
        #expect(source == RegistrationSource(assembly: "SomeAssembly", fileID: "App/Outer.swift", line: 1))
        #expect(RegistrationSource.current == RegistrationSource())
    }
}
