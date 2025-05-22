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
    func assemble(container: any Container) throws {
        try container.register(Protocols.Animal.self) { resolver in
            let b = try await resolver.resolve(Protocols.Building.self)
            let c = try await resolver.resolve(Protocols.Castle.self)
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            let d2 = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
        }
        
        try container.register(Protocols.Building.self) { resolver in
            let c = try await resolver.resolve(Protocols.Castle.self)
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectB(c: c, d: d)
        }
        
        try container.register(Protocols.Castle.self) { resolver in
            let d = try await resolver.resolve(Protocols.Dinosaur.self)
            return ObjectC(d: d)
        }
        
        try container.register(Protocols.Dinosaur.self) { resolver in
            ObjectD()
        }
        
        try container.register(ObjectA.self) { resolver in
            let b = try await resolver.resolve(ObjectB.self)
            let c = try await resolver.resolve(ObjectC.self)
            let d = try await resolver.resolve(ObjectD.self)
            let d2 = try await resolver.resolve(ObjectD.self)
            return ObjectA(b: b, c: c, d: d, d2: d2)
        }
        
        try container.register(ObjectB.self) { resolver in
            let c = try await resolver.resolve(ObjectC.self)
            let d = try await resolver.resolve(ObjectD.self)
            return ObjectB(c: c, d: d)
        }
        
        try container.register(ObjectC.self) { resolver in
            let d = try await resolver.resolve(ObjectD.self)
            return ObjectC(d: d)
        }
        
        try container.register(ObjectD.self) { resolver in
            ObjectD()
        }
        
        try container.register(ObjectE.self) { resolver in
            let f = try await resolver.resolve(ObjectF.self)
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectE(f: f, g: g)
        }
        
        try container.register(ObjectF.self) { resolver in
            let g = try await resolver.resolve(ObjectG.self)
            return ObjectF(g: g)
        }
        
        try container.register(ObjectG.self) {
            ObjectG(int: 1)
        }
    }
    
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
}

// swiftlint:enable identifier_name
