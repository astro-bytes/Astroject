//
//  swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable identifier_name

struct Classes: Assembly {
    class ObjectA: Protocols.Animal {
        let b: Protocols.Building
        let c: Protocols.Castle
        let d: Protocols.Dinosaur
        let d2: Protocols.Dinosaur
        init(b: Protocols.Building, c: Protocols.Castle, d: Protocols.Dinosaur, d2: Protocols.Dinosaur) {
            self.b = b
            self.c = c
            self.d = d
            self.d2 = d2
        }
    }
    
    class ObjectB: Protocols.Building {
        let c: Protocols.Castle
        let d: Protocols.Dinosaur
        init(c: Protocols.Castle, d: Protocols.Dinosaur) {
            self.c = c
            self.d = d
        }
    }
    
    class ObjectC: Protocols.Castle {
        let d: Protocols.Dinosaur
        init(d: Protocols.Dinosaur) {
            self.d = d
        }
    }
    
    class ObjectD: Protocols.Dinosaur {
        init() {}
    }
    
    class ObjectE {
        let f: ObjectF
        let g: ObjectG
        init(f: ObjectF, g: ObjectG) {
            self.f = f
            self.g = g
        }
    }
    
    class ObjectF {
        let g: ObjectG
        init(g: ObjectG) {
            self.g = g
        }
    }
    
    class ObjectG {
        let id: UUID = .init()
        let int: Int
        init(int: Int = 1) { self.int = int }
    }
    
    func assemble(container: any Container) throws {
        try asyncAssemble(container: container)
        try syncAssemble(container: container)
    }
    
    func asyncAssemble(container: any Container) throws {
        try container.register(Protocols.Animal.self, factory: Factory(.async { resolver in
            let b = try await resolver.resolve(Protocols.Building.self)
            let c = try await resolver.resolve(Protocols.Castle.self)
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            let d2 = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
        }))
        
        try container.register(Protocols.Building.self, factory: Factory(.async { resolver in
            let c = try await resolver.resolve(Protocols.Castle.self)
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectB(c: c, d: d)
        }))
        
        try container.register(Protocols.Castle.self, factory: Factory(.async { resolver in
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectC(d: d)
        }))
        
        try container.register(Protocols.Dinosaur.self, factory: Factory(.async { _ in
            ObjectD()
        }))
        
        try container.register(ObjectA.self, factory: Factory(.async { resolver in
            let b = try await resolver.resolve(ObjectB.self)
            let c = try await resolver.resolve(ObjectC.self)
            let d = try await resolver.resolve(ObjectD.self)
            let d2 = try await resolver.resolve(ObjectD.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
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
        
        try container.register(ObjectD.self, factory: Factory(.async { _ in
            ObjectD()
        }))
        
        try container.register(ObjectE.self, factory: Factory(.async { resolver in
            let f = try await resolver.resolve(ObjectF.self)
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectE(f: f, g: g)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.async { resolver in
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectF(g: g)
        }))
        
        try container.register(ObjectG.self, factory: Factory(.async { _ in
            ObjectG(int: 1)
        }))
    }
    
    func syncAssemble(container: any Container) throws {
        try container.register(Protocols.Animal.self, factory: Factory(.sync { resolver in
            let b = try resolver.resolve(Protocols.Building.self)
            let c = try resolver.resolve(Protocols.Castle.self)
            let d = try resolver.resolve(Protocols.Dinosaur.self)
            let d2 = try resolver.resolve(Protocols.Dinosaur.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
        }))
        
        try container.register(Protocols.Building.self, factory: Factory(.sync { resolver in
            let c = try resolver.resolve(Protocols.Castle.self)
            let d = try resolver.resolve(Protocols.Dinosaur.self)
            return ObjectB(c: c, d: d)
        }))
        
        try container.register(Protocols.Castle.self, factory: Factory(.sync { resolver in
            let d = try resolver.resolve(Protocols.Dinosaur.self)
            return ObjectC(d: d)
        }))
        
        try container.register(Protocols.Dinosaur.self, factory: Factory(.sync { _ in
            ObjectD()
        }))
        
        try container.register(ObjectA.self, factory: Factory(.sync { resolver in
            let b = try resolver.resolve(ObjectB.self)
            let c = try resolver.resolve(ObjectC.self)
            let d = try resolver.resolve(ObjectD.self)
            let d2 = try resolver.resolve(ObjectD.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
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
        
        try container.register(ObjectD.self, factory: Factory(.sync { _ in
            ObjectD()
        }))
        
        try container.register(ObjectE.self, factory: Factory(.sync { resolver in
            let f = try resolver.resolve(ObjectF.self)
            let g = try resolver.resolve(ObjectG.self)
            return ObjectE(f: f, g: g)
        }))
        
        try container.register(ObjectF.self, factory: Factory(.sync { resolver in
            let g = try resolver.resolve(ObjectG.self)
            return ObjectF(g: g)
        }))
        
        try container.register(ObjectG.self, factory: Factory(.sync { _ in
            ObjectG(int: 1)
        }))
    }
}

// swiftlint:enable identifier_name
