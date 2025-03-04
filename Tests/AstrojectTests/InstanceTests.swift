//
//  InstanceTests.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Astroject

@Suite("Instance")
struct InstanceTests {
    @Test func singleton() async {
        let instance = Singleton<Dog>()
        let dog = Dog()
        await instance.set(dog)
        let result = await instance.get()
        #expect(result != nil)
        #expect(result === dog)
    }
    
    @Test func prototype() {
        let instance = Prototype<Dog>()
        let dog = Dog()
        let result = instance.get()
        #expect(result == nil)
        #expect(result !== dog)
    }
    
    @Test func weak() async {
        let instance = Weak<Dog>()
        var dog: Dog? = Dog()
        await instance.set(dog!)
        let isNotNil = await instance.get() != nil
        #expect(isNotNil)
        let isObject = await instance.get() === dog
        #expect(isObject)
        dog = nil
        let isNil = await instance.get() == nil
        #expect(isNil)
    }
    
    @Test func composite() async {
        let prototype: Prototype<Dog> = .init()
        let weak: Weak<Dog> = .init()
        let instance = Composite<Dog>(instances: [prototype, weak])
        let dog1 = Dog()
        await weak.set(dog1)
        let isIdenticalObject = await instance.get() === dog1
        #expect(isIdenticalObject)
        
        let dog2 = Dog()
        let singleton = Singleton<Dog>()
        await singleton.set(dog2)
        
        let composite2 = Composite<Dog>(instances: [prototype, weak, singleton])
        let isIdenticalDog = await composite2.get() === dog1
        #expect(isIdenticalDog)
        
        await weak.release()
        let isIdenticalDog3 = await composite2.get() === dog2
        #expect(isIdenticalDog3)
    }
}
