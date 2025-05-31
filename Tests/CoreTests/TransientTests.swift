//
//  TransientTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Transient Tests")
struct TransientTests {
    @Test("Set Has No Effect")
    func whenSet_doNothing() {
        let transient = Transient<Int>()
        let context = MockContext.fresh()
        
        transient.set(67, for: context)
        transient.set(42, for: MockContext.fresh())
        
        #expect(transient.get(for: MockContext.fresh()) == nil)
        #expect(transient.get(for: context) == nil)
    }
    
    @Test("Get Returns Nil")
    func whenGet_returnNil() {
        let transient = Transient<Int>()
        
        #expect(transient.get(for: MockContext.fresh()) == nil)
    }
    
    @Test("Release has No Effect")
    func whenRelease_doNothing() {
        let transient = Transient<Int>()
        let context = MockContext.fresh()
        
        transient.set(67, for: context)
        
        transient.release(for: context)
        transient.release(for: MockContext.fresh())
        transient.releaseAll()
        
        #expect(transient.get(for: context) == nil)
    }
}
