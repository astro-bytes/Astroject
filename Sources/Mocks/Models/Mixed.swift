//
//  Mixed.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

struct Mixed: Assembly {
    class ObjectA {
        let b: ObjectB
        init(b: ObjectB) {
            self.b = b
        }
    }
    
    struct ObjectB {
        let c: ObjectC
        let d: ObjectD
    }
    
    class ObjectC {
        let d: ObjectD
        init(d: ObjectD) {
            self.d = d
        }
    }
    
    struct ObjectD {
        let e: ObjectE
        let f: ObjectF
        let g: ObjectG
    }
    
    class ObjectE {
        let g: ObjectG
        init(g: ObjectG) {
            self.g = g
        }
    }
    
    struct ObjectF {
        let g: ObjectG
    }
    
    class ObjectG {
        init() {}
    }
    
    func assemble(container: any Container) throws {
        fatalError("Needs Implemented")
    }
    
    func asyncAssemble(container: any Container) throws {}
    func syncAssemble(container: any Container) throws {}
}
