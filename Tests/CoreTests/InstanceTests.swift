//
//  InstanceTests.swift
//  CoreTests
//
//  Created by Porter McGary on 2/27/25.
//

import Testing
import Foundation
@testable import AstrojectCore

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
}
