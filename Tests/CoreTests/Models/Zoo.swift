//
//  Zoo.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation

struct Zoo: Equatable {
    static func == (lhs: Zoo, rhs: Zoo) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID = .init()
    var animals: [Animal]
    
    init(animals: [Animal]) {
        self.animals = animals
    }
}
