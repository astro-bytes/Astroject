//
//  DisposableSingletonTests.swift
//  Astroject
//
//  Created by Porter McGary on 9/19/25.
//

import Testing
@testable import AstrojectCore

@Suite("Singleton Tests")
struct DisposableSingletonTest {
    @Test("Init with Empty Product")
    func initialization() {
        let singleton = DisposableSingleton<Int>()
        
        #expect(singleton.product == nil)
    }
    
    @Test("Set with Context")
    func whenSetFirstTime_setValue() {
        let singleton = DisposableSingleton<Int>()
        
        singleton.set(1, for: ResolutionContext.fresh())
        
        #expect(singleton.product == 1)
    }
    
    @Test("Setting does not Override")
    func whenSetAgain_doNothing() {
        let singleton = DisposableSingleton<Int>()
        let context = ResolutionContext.fresh()
        
        singleton.set(1, for: context)
        singleton.set(2, for: context)
        singleton.set(3, for: ResolutionContext.fresh())
        
        #expect(singleton.product == 1)
    }
    
    @Test("Get")
    func whenValueSet_returnValue() {
        let singleton = DisposableSingleton<Int>()
        let context = ResolutionContext.fresh()
        
        singleton.set(1, for: context)
        
        #expect(singleton.get(for: context) == 1)
    }
    
    @Test("Get when Nothing is Set")
    func whenNothingIsSet_returnNil() {
        let singleton = DisposableSingleton<Int>()
        
        #expect(singleton.get(for: ResolutionContext.fresh()) == nil)
    }
    
    @Test("Release Does Nothing")
    func whenRelease_doNothing() {
        let singleton = DisposableSingleton<Int>()
        let context = ResolutionContext.fresh()
        
        singleton.set(1, for: context)
        
        singleton.release(for: context)
        singleton.release(for: ResolutionContext.fresh())
        singleton.releaseAll()
        
        #expect(singleton.product == nil)
    }
}
