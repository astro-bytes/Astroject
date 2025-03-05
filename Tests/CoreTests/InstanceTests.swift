//
//  InstanceTests.swift
//  CoreTests
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import Core

@Suite("Instance")
struct InstanceTests {
    @Test func singleton() {
        let instance = Singleton<ClassAnimal>()
        let dog = ClassAnimal()
        instance.set(dog)
        let result = instance.get()
        #expect(result != nil)
        #expect(result === dog)
    }
    
    @Test func prototype() {
        let instance = Prototype<ClassAnimal>()
        let dog = ClassAnimal()
        let result = instance.get()
        #expect(result == nil)
        #expect(result !== dog)
    }
    
    @Test func weak() {
        let instance = Weak<ClassAnimal>()
        var dog: ClassAnimal? = ClassAnimal()
        instance.set(dog!)
        #expect(instance.get() != nil)
        #expect(instance.get() === dog)
        dog = nil
        #expect(instance.get() == nil)
    }
    
    @Test func composite() {
        let prototype: Prototype<ClassAnimal> = .init()
        let weak: Weak<ClassAnimal> = .init()
        let instance = Composite<ClassAnimal>(instances: [prototype, weak])
        let dog1 = ClassAnimal()
        weak.set(dog1)
        #expect(instance.get() === dog1)
        
        let dog2 = ClassAnimal()
        let singleton = Singleton<ClassAnimal>()
        singleton.set(dog2)
        
        let composite2 = Composite<ClassAnimal>(instances: [prototype, weak, singleton])
        #expect(composite2.get() === dog1)
        
        weak.release()
        #expect(composite2.get() === dog2)
    }
}
