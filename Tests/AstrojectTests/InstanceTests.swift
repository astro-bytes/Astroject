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
    @Test func singleton() {
        let instance = Singleton<Dog>()
        let dog = Dog()
        instance.set(dog)
        let result = instance.get()
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
    
    @Test func weak() {
        let instance = Weak<Dog>()
        var dog: Dog? = Dog()
        instance.set(dog!)
        #expect(instance.get() != nil)
        #expect(instance.get() === dog)
        dog = nil
        #expect(instance.get() == nil)
    }
    
    @Test func composite() {
        let prototype: Prototype<Dog> = .init()
        let weak: Weak<Dog> = .init()
        let instance = Composite<Dog>(instances: [prototype, weak])
        let dog1 = Dog()
        weak.set(dog1)
        #expect(instance.get() === dog1)
        
        let dog2 = Dog()
        let singleton = Singleton<Dog>()
        singleton.set(dog2)
        
        let composite2 = Composite<Dog>(instances: [prototype, weak, singleton])
        #expect(composite2.get() === dog1)
        
        weak.release()
        #expect(composite2.get() === dog2)
    }
}
