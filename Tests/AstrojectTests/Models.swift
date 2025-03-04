import Foundation

protocol Animal: Sendable {
    var name: String { get }
    
    func isEqual(to other: Animal) async -> Bool
}

extension Animal {
    func isEqual(to other: Animal) async -> Bool {
        if let other = other as? Self {
            return other.name == self.name
        } else {
            return false
        }
    }
}

struct Home {
    var cat: Cat
    var dog: Dog
    
    init(cat: Cat, dog: Dog) {
        self.cat = cat
        self.dog = dog
    }
}

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

struct Cat: Animal {
    var name: String = "Whiskers"
}

actor Dog: Animal {
    let name: String
    
    init(name: String = "Max") {
        self.name = name
    }
}

final class Fish: Animal, Equatable {
    static func == (lhs: Fish, rhs: Fish) -> Bool {
        lhs.name == rhs.name
    }
    
    let name: String
    
    init(name: String = "Nemo") {
        self.name = name
    }
}

actor Horse: @preconcurrency Animal {
    var name: String = "Silver"
}

@MainActor
class Pig: Animal {
    let name: String
    
    init(name: String = "Hamlet") {
        self.name = name
    }
}

actor ClassA: Sendable {
    weak var classB: ClassB?
    
    init(classB: ClassB?) {
        self.classB = classB
    }
}

actor ClassB: Sendable {
    var classA: ClassA?
    
    init(classA: ClassA?) {
        self.classA = classA
    }
}
