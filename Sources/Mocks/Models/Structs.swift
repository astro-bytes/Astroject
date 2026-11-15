//
//  Structs.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

struct Structs: Assembly {
    struct ObjectA {
        let b: ObjectB
    }
    
    struct ObjectB {
        let c: ObjectC
        let d: ObjectD
    }
    
    struct ObjectC {
        let d: ObjectD
    }
    
    struct ObjectD {
        let e: ObjectE
        let f: ObjectF
        let g: ObjectG
    }
    
    struct ObjectE {
        let g: ObjectG
    }
    
    struct ObjectF {
        let g: ObjectG
    }
    
    struct ObjectG {}
    
    func assemble(container: any Container) throws {
        try asyncAssemble(container: container)
        try syncAssemble(container: container)
    }
    
    func asyncAssemble(container: any Container) throws {
        try container.register(ObjectA.self, factory: Factory(.async { resolver in
            let b = try await resolver.resolve(ObjectB.self)
            return ObjectA(b: b)
        }))
        
        try container.register(ObjectB.self, factory: Factory(.async { resolver in
            let c = try await resolver.resolve(ObjectC.self)
            let d = try await resolver.resolve(ObjectD.self)
            return ObjectB(c: c, d: d)
        }))
        
        try container.register(ObjectC.self, factory: Factory(.async { resolver in
            let d = try await resolver.resolve(ObjectD.self)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, factory: Factory(.async { resolver in
            let e = try await resolver.resolve(ObjectE.self)
            let f = try await resolver.resolve(ObjectF.self)
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectD(e: e, f: f, g: g)
        }))
        
        try container.register(ObjectE.self, factory: Factory(.async { resolver in
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectE(g: g)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.async { resolver in
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectF(g: g)
        }))
        
        try container.register(ObjectG.self, factory: Factory(.async { _ in
            ObjectG()
        }))
    }
    
    func syncAssemble(container: any Container) throws {
        try container.register(ObjectA.self, factory: Factory(.sync { resolver in
            let b = try resolver.resolve(ObjectB.self)
            return ObjectA(b: b)
        }))
        
        try container.register(ObjectB.self, factory: Factory(.sync { resolver in
            let c = try resolver.resolve(ObjectC.self)
            let d = try resolver.resolve(ObjectD.self)
            return ObjectB(c: c, d: d)
        }))
        
        try container.register(ObjectC.self, factory: Factory(.sync { resolver in
            let d = try resolver.resolve(ObjectD.self)
            return ObjectC(d: d)
        }))
        
        try container.register(ObjectD.self, factory: Factory(.sync { resolver in
            let e = try resolver.resolve(ObjectE.self)
            let f = try resolver.resolve(ObjectF.self)
            let g = try resolver.resolve(ObjectG.self)
            return ObjectD(e: e, f: f, g: g)
        }))
        
        try container.register(ObjectE.self, factory: Factory(.sync { resolver in
            let g = try resolver.resolve(ObjectG.self)
            return ObjectE(g: g)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.sync { resolver in
            let g = try resolver.resolve(ObjectG.self)
            return ObjectF(g: g)
        }))
        
        try container.register(ObjectG.self, factory: Factory(.sync { _ in
            ObjectG()
        }))
    }
}
