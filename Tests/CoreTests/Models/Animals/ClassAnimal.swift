//
//  ClassAnimal.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation

class ClassAnimal: Animal, Equatable {
    static func == (lhs: ClassAnimal, rhs: ClassAnimal) -> Bool {
        lhs.name == rhs.name
    }
    let id: UUID = .init()
    var name: String = "Max"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}
