//
//  Structs.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable identifier_name

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
        fatalError("Needs Implemented")
    }
}

// swiftlint:enable identifier_name
