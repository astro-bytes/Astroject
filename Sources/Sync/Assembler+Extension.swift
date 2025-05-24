//
//  Assembler+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

public extension Assembler {
    convenience init(_ container: Container = SyncContainer()) {
        self.init(container: container)
    }
    
    convenience init(_ assemblies: [Assembly], container: Container = SyncContainer()) throws {
        try self.init(assemblies: assemblies, container: container)
    }
    
    convenience init(_ assembly: Assembly, container: Container =  SyncContainer()) throws {
        try self.init(assembly: assembly, container: container)
    }
}
