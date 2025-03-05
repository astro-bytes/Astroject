//
//  Home.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//


struct Home: Equatable {
    var cat: StructAnimal
    var dog: ClassAnimal
    
    init(cat: StructAnimal, dog: ClassAnimal) {
        self.cat = cat
        self.dog = dog
    }
}
