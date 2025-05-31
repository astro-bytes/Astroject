//
//  MockContext.swift
//  Astroject
//
//  Created by Porter McGary on 5/31/25.
//

import Foundation
import AstrojectCore

final class MockContext: Context, @unchecked Sendable {
    @TaskLocal static var currentContext: MockContext = .init()
    static var current: TaskLocal<MockContext> { $currentContext }
    
    nonisolated(unsafe) static var whenFresh: () -> MockContext = { MockContext() }
    
    static func fresh() -> MockContext {
        whenFresh()
    }
    
    var callsNext = false
    var callsPush = false
    var callsPop = false
    
    var whenNext: () -> MockContext = { .init() }
    var whenPush: () -> MockContext = { .init() }
    var whenPop: () -> MockContext = { .init() }
    
    var depth: Int = 0
    var graphID: UUID = .init()
    var graph: [RegistrationKey] = []
    
    init() {}
    
    func next() -> MockContext {
        callsNext = true
        return whenNext()
    }
    
    func push(_ key: RegistrationKey) -> MockContext {
        callsPush = true
        return whenPush()
    }
    
    func pop() -> MockContext {
        callsPop = true
        return whenPop()
    }
}
