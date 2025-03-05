//
//  FinalClassAnimal.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

final class FinalClassAnimal: Animal, Equatable {
    static func == (lhs: FinalClassAnimal, rhs: FinalClassAnimal) -> Bool {
        lhs.name == rhs.name
    }
    
    var name: String = "Nemo"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}
