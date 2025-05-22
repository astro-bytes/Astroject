//
//  CircularDependency.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable nesting
// swiftlint:disable identifier_name

struct CircularDependency: Assembly {
    func assemble(container: any Container) throws {
        try Classes().assemble(container: container)
        try Mixed().assemble(container: container)
    }
    
    struct Classes: Assembly {
        // Simple Cyclical
        class ObjectA {
            let b: ObjectB
            init(b: ObjectB) {
                self.b = b
            }
        }
        
        class ObjectB {
            let a: ObjectA
            init(a: ObjectA) {
                self.a = a
            }
        }
        
        // Complex Cyclical
        class ObjectC {
            let d: ObjectD
            init(d: ObjectD) {
                self.d = d
            }
        }
        
        class ObjectD {
            let e: ObjectE
            init(e: ObjectE) {
                self.e = e
            }
        }
        
        class ObjectE {
            let f: ObjectF
            let d: ObjectD
            
            init(f: ObjectF, d: ObjectD) {
                self.f = f
                self.d = d
            }
        }
        
        class ObjectF {
            init() {}
        }
        
        // Self Cyclical
        class ObjectG {
            let g: ObjectG
            init(g: ObjectG) {
                self.g = g
            }
        }
        
        func assemble(container: any Container) throws {
            try container.register(ObjectA.self) { resolver in
                let b = try await resolver.resolve(ObjectB.self)
                return .init(b: b)
            }
            
            try container.register(ObjectB.self) { resolver in
                let a = try await resolver.resolve(ObjectA.self)
                return ObjectB(a: a)
            }
            
            try container.register(ObjectC.self) { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                return ObjectC(d: d)
            }
            
            try container.register(ObjectD.self) { resolver in
                let e = try await resolver.resolve(ObjectE.self)
                return ObjectD(e: e)
            }
            
            try container.register(ObjectE.self) { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                let f = try await resolver.resolve(ObjectF.self)
                return ObjectE(f: f, d: d)
            }
            
            try container.register(ObjectF.self) { resolver in
                ObjectF()
            }
            
            try container.register(ObjectG.self) { resolver in
                let g = try await resolver.resolve(ObjectG.self)
                return ObjectG(g: g)
            }
            
            try container.register(ObjectA.self, name: "test") { resolver in
                let b = try await resolver.resolve(ObjectB.self)
                return .init(b: b)
            }
            
            try container.register(ObjectB.self, name: "test") { resolver in
                let a = try await resolver.resolve(ObjectA.self)
                return ObjectB(a: a)
            }
            
            try container.register(ObjectC.self, name: "test") { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                return ObjectC(d: d)
            }
            
            try container.register(ObjectD.self, name: "test") { resolver in
                let e = try await resolver.resolve(ObjectE.self)
                return ObjectD(e: e)
            }
            
            try container.register(ObjectE.self, name: "test") { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                let f = try await resolver.resolve(ObjectF.self)
                return ObjectE(f: f, d: d)
            }
            
            try container.register(ObjectF.self, name: "test") { resolver in
                ObjectF()
            }
            
            try container.register(ObjectG.self, name: "test") { resolver in
                let g = try await resolver.resolve(ObjectG.self)
                return ObjectG(g: g)
            }
            
            try container.register(ObjectA.self, argument: Int.self) { resolver, _ in
                let b = try await resolver.resolve(ObjectB.self)
                return .init(b: b)
            }
            
            try container.register(ObjectB.self, argument: Int.self) { resolver, _ in
                let a = try await resolver.resolve(ObjectA.self)
                return ObjectB(a: a)
            }
            
            try container.register(ObjectC.self, argument: Int.self) { resolver, _ in
                let d = try await resolver.resolve(ObjectD.self)
                return ObjectC(d: d)
            }
            
            try container.register(ObjectD.self, argument: Int.self) { resolver, _ in
                let e = try await resolver.resolve(ObjectE.self)
                return ObjectD(e: e)
            }
            
            try container.register(ObjectE.self, argument: Int.self) { resolver, _ in
                let d = try await resolver.resolve(ObjectD.self)
                let f = try await resolver.resolve(ObjectF.self)
                return ObjectE(f: f, d: d)
            }
            
            try container.register(ObjectF.self, argument: Int.self) { resolver, _ in
                ObjectF()
            }
            
            try container.register(ObjectG.self, argument: Int.self) { resolver, _ in
                let g = try await resolver.resolve(ObjectG.self)
                return ObjectG(g: g)
            }
        }
    }
    
    struct Mixed: Assembly {
        // Simple Cyclical
        class ObjectA {
            let b: ObjectB
            init(b: ObjectB) {
                self.b = b
            }
        }
        
        struct ObjectB {
            let a: ObjectA
        }
        
        // Complex Cyclical
        class ObjectC {
            let d: ObjectD
            init(d: ObjectD) {
                self.d = d
            }
        }
        
        struct ObjectD {
            let e: ObjectE
        }
        
        class ObjectE {
            let f: ObjectF
            let d: ObjectD
            
            init(f: ObjectF, d: ObjectD) {
                self.f = f
                self.d = d
            }
        }
        
        struct ObjectF {}
        
        func assemble(container: any Container) throws {
            try container.register(ObjectA.self) { resolver in
                let b = try await resolver.resolve(ObjectB.self)
                return ObjectA(b: b)
            }
            
            try container.register(ObjectB.self) { resolver in
                let a = try await resolver.resolve(ObjectA.self)
                return ObjectB(a: a)
            }
            
            try container.register(ObjectC.self) { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                return ObjectC(d: d)
            }
            
            try container.register(ObjectD.self) { resolver in
                let e = try await resolver.resolve(ObjectE.self)
                return ObjectD(e: e)
            }
            
            try container.register(ObjectE.self) { resolver in
                let d = try await resolver.resolve(ObjectD.self)
                let f = try await resolver.resolve(ObjectF.self)
                return ObjectE(f: f, d: d)
            }
            
            try container.register(ObjectF.self) {
                ObjectF()
            }
        }
    }
}

// swiftlint:enable nesting
// swiftlint:enable identifier_name
