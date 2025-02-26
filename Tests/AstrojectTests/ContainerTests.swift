import Testing
@testable import Astroject

protocol Animal {
    var name: String { get }
}

struct Cat: Animal {
    var name: String = "Whiskers"
}

class Dog: Animal {
    var name: String = "Max"
}

final class Fish: Animal {
    var name: String = "Nemo"
}

@Test func testClassRegistration() async throws {
    let container = Container()
    container.register(Animal.self) { resolver in
        Dog()
    }
    container.
}
