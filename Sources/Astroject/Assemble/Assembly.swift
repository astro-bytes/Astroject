//
//  Assembly.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

public protocol Assembly {
    func assemble(container: Container)
    func loaded(resolver: Resolver)
}

public extension Assembly {
    func loaded(resolver: Resolver) {}
}
