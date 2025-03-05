//
//  ClassAnimal.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

class ClassAnimal: Animal, Equatable {
    static func == (lhs: ClassAnimal, rhs: ClassAnimal) -> Bool {
        lhs.name == rhs.name
    }
    
    var name: String = "Max"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}
