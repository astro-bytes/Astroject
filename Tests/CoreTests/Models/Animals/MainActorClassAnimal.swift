//
//  MainActorClassAnimal.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

@MainActor
class MainActorClassAnimal: @preconcurrency Animal {
    var name: String = "Hamlet"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}
