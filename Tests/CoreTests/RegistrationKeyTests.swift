//
//  RegistrationKeyTests.swift
//  Astroject
//
//  Created by Porter McGary on 5/28/25.
//

import Testing
@testable import Mocks
@testable import AstrojectCore

@Suite("Registration Key Tests")
struct RegistrationKeyTests {
    @Test("Init with No Argument")
    func initWithNoArgument() {
        typealias F = Factory<Int, Resolver>
        let factory = F(.sync { _ in 1 })
        
        let namedKey = RegistrationKey(factory: factory, name: "test")
        let r1 = namedKey.productType == Int.self
        let r2 = namedKey.factoryType == F.SyncBlock.self
        let r3 = namedKey.argumentType == Empty.self
        let r4 = namedKey.name == "test"
        
        #expect(r1)
        #expect(r2)
        #expect(r3)
        #expect(r4)
        
        let key = RegistrationKey(factory: factory)
        let r5 = key.productType == Int.self
        let r6 = key.factoryType == F.SyncBlock.self
        let r7 = key.argumentType == Empty.self
        let r8 = key.name == nil
        
        #expect(r5)
        #expect(r6)
        #expect(r7)
        #expect(r8)
    }
    
    @Test("Init with Argument")
    func initWithArgument() {
        typealias F = Factory<Int, (Resolver, Int)>
        let factory = F(.async { _ in 1 })
        
        let namedKey = RegistrationKey(factory: factory, name: "test")
        let r1 = namedKey.productType == Int.self
        let r2 = namedKey.factoryType == F.AsyncBlock.self
        let r3 = namedKey.argumentType == Int.self
        let r4 = namedKey.name == "test"
        #expect(r1)
        #expect(r2)
        #expect(r3)
        #expect(r4)
        
        let key = RegistrationKey(factory: factory)
        let r5 = key.productType == Int.self
        let r6 = key.factoryType == F.AsyncBlock.self
        let r7 = key.argumentType == Int.self
        let r8 = key.name == nil
        #expect(r5)
        #expect(r6)
        #expect(r7)
        #expect(r8)
    }
    
    @Suite("Equality")
    struct Equality {
        @Test("Happy Path")
        func whenAllIsEqual() {
            let factory = Factory<Int, Resolver>(.sync { _ in 1 })
            let key1 = RegistrationKey(factory: factory)
            let key2 = RegistrationKey(factory: factory)
            
            #expect(key1 == key2)
            #expect(key1.hashValue == key2.hashValue)
        }
        
        @Test("Names Differ")
        func whenNamesDiffer() {
            let factory = Factory<Int, Resolver>(.async({ _ in 1 }))
            let key1 = RegistrationKey(factory: factory, name: "test1")
            let key2 = RegistrationKey(factory: factory, name: "test2")
            let key3 = RegistrationKey(factory: factory)
            
            #expect(key1 != key2)
            #expect(key1 != key3)
            #expect(key2 != key3)
            #expect(key1.hashValue != key2.hashValue)
            #expect(key2.hashValue != key3.hashValue)
            #expect(key3.hashValue != key1.hashValue)
        }
        
        @Test("ProductTypes Differ")
        func whenProductTypesDiffer() {
            let factory1 = Factory<Int, Resolver>(.sync { _ in 1 })
            let factory2 = Factory<String, Resolver>(.sync { _ in "1" })
            let key1 = RegistrationKey(factory: factory1)
            let key2 = RegistrationKey(factory: factory2)
            
            #expect(key1 != key2)
            #expect(key1.hashValue != key2.hashValue)
        }
        
        @Test("ArgumentTypes Differ")
        func whenArgumentTypesDiffer() {
            let factory1 = Factory<Int, (Resolver, Int)>(.async { _ in 1 })
            let factory2 = Factory<Int, (Resolver, String)>(.async { _ in 1 })
            let key1 = RegistrationKey(factory: factory1)
            let key2 = RegistrationKey(factory: factory2)
            
            #expect(key1 != key2)
            #expect(key1.hashValue != key2.hashValue)
        }
        
        @Test("Factory.Block Types Differ")
        func whenFactoryBlockTypesDiffer() {
            let factory1 = Factory<Int, Resolver>(.sync { _ in 1 })
            let factory2 = Factory<Int, Resolver>(.async { _ in 1 })
            let key1 = RegistrationKey(factory: factory1)
            let key2 = RegistrationKey(factory: factory2)
            
            #expect(key1 != key2)
            #expect(key1.hashValue != key2.hashValue)
        }
    }
}
