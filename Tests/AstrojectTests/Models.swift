import Foundation

protocol Animal {
    var name: String { get }
}

struct Home: Equatable {
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

struct Cat: Animal, Equatable {
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

class ClassA {
    weak var classB: ClassB?
    
    init(classB: ClassB?) {
        self.classB = classB
    }
}

class ClassB {
    var classA: ClassA?
    
    init(classA: ClassA?) {
        self.classA = classA
    }
}
