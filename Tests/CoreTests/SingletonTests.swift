//
//  SingletonTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/30/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Singleton Tests")
struct SingletonTest {
    @Test("Init with Empty Product")
    func initialization() {
        let singleton = Singleton<Int>()
        
        #expect(singleton.product == nil)
    }
    
    @Test("Set with Context")
    func setWithContext() {
        let singleton = Singleton<Int>()
        
        singleton.set(1, for: Context.fresh())
        
        #expect(singleton.product == 1)
    }
    
    @Test("Setting does not Override")
    func notOverridable() {
        let singleton = Singleton<Int>()
        let context = Context.fresh()
        
        singleton.set(1, for: context)
        singleton.set(2, for: context)
        singleton.set(3, for: Context.fresh())
        
        #expect(singleton.product == 1)
    }
    
    @Test("Get")
    func get() {
        let singleton = Singleton<Int>()
        let context = Context.fresh()
        
        singleton.set(1, for: context)
        
        #expect(singleton.get(for: context) == 1)
    }
    
    @Test("Get when Nothing is Set")
    func getWhenNothingIsSet() {
        let singleton = Singleton<Int>()
        
        #expect(singleton.get(for: Context.fresh()) == nil)
    }
    
    @Test("Release Does Nothing")
    func releaseDoesNothing() {
        let singleton = Singleton<Int>()
        let context = Context.fresh()
        
        singleton.set(1, for: context)
        
        singleton.release(for: context)
        singleton.release(for: Context.fresh())
        singleton.releaseAll()
        
        #expect(singleton.product == 1)
    }
}
