//
//  CircularDependency.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable identifier_name
// swiftlint:disable function_body_length

struct CircularDependency: Assembly {
    
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
        try asyncAssemble(container: container)
        try syncAssemble(container: container)
    }
    
    func asyncAssemble(container: any Container) throws {
        try container.register(ObjectA.self, factory: Factory(.async { resolver in
            let b = try await resolver.resolve(ObjectB.self)
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, factory: Factory(.async { resolver in
            let a = try await resolver.resolve(ObjectA.self)
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, factory: Factory(.async { resolver in
            let d = try await resolver.resolve(ObjectD.self)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, factory: Factory(.async { resolver in
            let e = try await resolver.resolve(ObjectE.self)
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, factory: Factory(.async { resolver in
            let d = try await resolver.resolve(ObjectD.self)
            let f = try await resolver.resolve(ObjectF.self)
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.async { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, factory: Factory(.async { resolver in
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectG(g: g)
        }))
        
        try container.register(ObjectA.self, name: "test", factory: Factory(.async { resolver in
            let b = try await resolver.resolve(ObjectB.self, name: "test")
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, name: "test", factory: Factory(.async { resolver in
            let a = try await resolver.resolve(ObjectA.self, name: "test")
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, name: "test", factory: Factory(.async { resolver in
            let d = try await resolver.resolve(ObjectD.self, name: "test")
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, name: "test", factory: Factory(.async { resolver in
            let e = try await resolver.resolve(ObjectE.self, name: "test")
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, name: "test", factory: Factory(.async { resolver in
            let d = try await resolver.resolve(ObjectD.self, name: "test")
            let f = try await resolver.resolve(ObjectF.self, name: "test")
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, name: "test", factory: Factory(.async { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, name: "test", factory: Factory(.async { resolver in
            let g = try await resolver.resolve(ObjectG.self, name: "test")
            return ObjectG(g: g)
        }))
        
        try container.register(ObjectA.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let b = try await resolver.resolve(ObjectB.self, argument: 1)
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let a = try await resolver.resolve(ObjectA.self, argument: 1)
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let d = try await resolver.resolve(ObjectD.self, argument: 1)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let e = try await resolver.resolve(ObjectE.self, argument: 1)
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let d = try await resolver.resolve(ObjectD.self, argument: 1)
            let f = try await resolver.resolve(ObjectF.self, argument: 1)
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, argumentType: Int.self, factory: Factory(.async { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, argumentType: Int.self, factory: Factory(.async { resolver, _ in
            let g = try await resolver.resolve(ObjectG.self, argument: 1)
            return ObjectG(g: g)
        }))
    }
    
    func syncAssemble(container: any Container) throws {
        try container.register(ObjectA.self, factory: Factory(.sync { resolver in
            let b = try resolver.resolve(ObjectB.self)
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, factory: Factory(.sync { resolver in
            let a = try resolver.resolve(ObjectA.self)
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, factory: Factory(.sync { resolver in
            let d = try resolver.resolve(ObjectD.self)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, factory: Factory(.sync { resolver in
            let e = try resolver.resolve(ObjectE.self)
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, factory: Factory(.sync { resolver in
            let d = try resolver.resolve(ObjectD.self)
            let f = try resolver.resolve(ObjectF.self)
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.sync { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, factory: Factory(.sync { resolver in
            let g = try resolver.resolve(ObjectG.self)
            return ObjectG(g: g)
        }))
        
        try container.register(ObjectA.self, name: "test", factory: Factory(.sync { resolver in
            let b = try resolver.resolve(ObjectB.self, name: "test")
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, name: "test", factory: Factory(.sync { resolver in
            let a = try resolver.resolve(ObjectA.self, name: "test")
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, name: "test", factory: Factory(.sync { resolver in
            let d = try resolver.resolve(ObjectD.self, name: "test")
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, name: "test", factory: Factory(.sync { resolver in
            let e = try resolver.resolve(ObjectE.self, name: "test")
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, name: "test", factory: Factory(.sync { resolver in
            let d = try resolver.resolve(ObjectD.self, name: "test")
            let f = try resolver.resolve(ObjectF.self, name: "test")
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, name: "test", factory: Factory(.sync { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, name: "test", factory: Factory(.sync { resolver in
            let g = try resolver.resolve(ObjectG.self, name: "test")
            return ObjectG(g: g)
        }))
        
        try container.register(ObjectA.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let b = try resolver.resolve(ObjectB.self, argument: 1)
            return .init(b: b)
        }))
        
        try container.register(ObjectB.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let a = try resolver.resolve(ObjectA.self, argument: 1)
            return ObjectB(a: a)
        }))
        
        try container.register(ObjectC.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let d = try resolver.resolve(ObjectD.self, argument: 1)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let e = try resolver.resolve(ObjectE.self, argument: 1)
            return ObjectD(e: e)
        }))
        
        try container.register(ObjectE.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let d = try resolver.resolve(ObjectD.self, argument: 1)
            let f = try resolver.resolve(ObjectF.self, argument: 1)
            return ObjectE(f: f, d: d)
        }))
        
        try container.register(ObjectF.self, argumentType: Int.self, factory: Factory(.sync { _ in
            ObjectF()
        }))
        
        try container.register(ObjectG.self, argumentType: Int.self, factory: Factory(.sync { resolver, _ in
            let g = try resolver.resolve(ObjectG.self, argument: 1)
            return ObjectG(g: g)
        }))
    }
    
}

// swiftlint:enable identifier_name
// swiftlint:enable function_body_length
