//
//  Assembler.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

public class Assembler {
    let container: Container
    
    var resolver: Resolver { container }
    
    init(container: Container) {
        self.container = container
    }
    
    public func apply(assembly: Assembly) {
        run(assemblies: [assembly])
    }
    
    public func apply(assemblies: [Assembly]) {
        run(assemblies: assemblies)
    }
    
    func run(assemblies: [Assembly]) {
        assemblies.forEach { $0.assemble(container: container) }
        assemblies.forEach { $0.loaded(resolver: resolver) }
    }
}
