//
//  WeakTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Weak Tests")
struct WeakTests {
    typealias D = Classes.ObjectD
    
    @Test("Init")
    func initialization() {
        let weak = Weak<D>()
        
        #expect(weak.product == nil)
    }
    
    @Test("Set")
    func whenSet_setValue() {
        let weak = Weak<D>()
        let context = MockContext.fresh()
        let expected = D()
        weak.set(expected, for: context)
        weak.set(D(), for: context)
        weak.set(D(), for: MockContext.fresh())
        
        #expect(weak.product === expected)
    }
    
    @Test("Get")
    func whenGetAndValueExists_returnValue() {
        let weak = Weak<D>()
        let context = MockContext.fresh()
        let expected = D()
        
        weak.set(expected, for: context)
        weak.set(D(), for: context)
        weak.set(D(), for: MockContext.fresh())
        
        #expect(weak.get(for: MockContext.fresh()) === expected)
        #expect(weak.get(for: context) === expected)
    }
    
    @Test("Release")
    func whenReleaseAndValueExists_removeValue() {
        let weak = Weak<D>()
        let context = MockContext.fresh()
        
        weak.set(D(), for: context)
        weak.release(for: MockContext.fresh())
        #expect(weak.product == nil)
        
        weak.set(D(), for: context)
        weak.release(for: context)
        #expect(weak.product == nil)
        
        weak.set(D(), for: context)
        weak.releaseAll()
        #expect(weak.product == nil)
    }
    
    @Test("Set Release Set Get")
    func whenGetAfterSetReleaseSet_returnSecondValue() {
        let weak = Weak<D>()
        let expected = D()
        
        weak.set(D(), for: MockContext.fresh())
        weak.release(for: MockContext.fresh())
        weak.set(expected, for: MockContext.fresh())
        
        #expect(weak.product === expected)
    }
    
    @Test("Auto Release")
    func whenSetToNilOutOfInstance_weakReferenceIsNil() {
        let weak = Weak<D>()
        var expected: D? = D()
        
        weak.set(expected!, for: MockContext.fresh())
        #expect(weak.product === expected)
        
        expected = nil
        #expect(weak.product == nil)
    }
    
    @Test("Auto Release Out of Scope")
    func whenReleasedFromAllScopes_weakReferenceIsNil() {
        let `weak` = Weak<D>()
        weak var ref: D?
        
        do {
            let temp = D()
            ref = temp
            `weak`.set(temp, for: MockContext.fresh())
        }
        
        // ref should now be nil, because `temp` is out of scope
        #expect(ref == nil)
        #expect(`weak`.product == nil)
    }
}
