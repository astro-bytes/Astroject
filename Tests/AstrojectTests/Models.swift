//
//  File.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

protocol Animal {
    var name: String { get }
}

struct Cat: Animal {
    var name: String = "Whiskers"
}

class Dog: Animal, Equatable {
    static func == (lhs: Dog, rhs: Dog) -> Bool {
        lhs.name == rhs.name
    }
    
    var name: String = "Max"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}

final class Fish: Animal, Equatable {
    static func == (lhs: Fish, rhs: Fish) -> Bool {
        lhs.name == rhs.name
    }
    
    var name: String = "Nemo"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}

actor Horse: @preconcurrency Animal {
    var name: String = "Silver"
}

@MainActor
class Pig: @preconcurrency Animal {
    var name: String = "Hamlet"
    
    init() {}
    
    init(name: String) {
        self.name = name
    }
}
