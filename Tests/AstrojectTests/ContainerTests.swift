import Testing
@testable import Astroject

@Test func testStructRegistration() async throws {
    let container = Container()
    container.register(Animal.self) { resolver in
        Cat(name: "john")
    }
    let key = FactoryKey(productType: Animal.self)
    let result = container.factories.getValue(for: key) as? FactoryRegistration<Animal>
    #expect("john" == result?.factory.make(container).name)
}

@Test func testClassRegistration() async throws {
    let container = Container()
    container.register(Animal.self) { resolver in
        Dog(name: "john")
    }
    let key = FactoryKey(productType: Animal.self)
    let result = container.factories.getValue(for: key) as? FactoryRegistration<Animal>
    #expect("john" == result?.factory.make(container).name)
}

@Test func testMultipleRegistration() async throws {
    let container = Container()
    container.register(Animal.self) { resolver in
        Dog(name: "john")
    }
    
    container.register(Animal.self) { resolver in
        Dog(name: "peter")
    }
    
    let key = FactoryKey(productType: Animal.self)
    let result = container.factories.getValue(for: key) as? FactoryRegistration<Animal>
    #expect("peter" == result?.factory.make(container).name)
}

@Test func testActorRegistration() async throws {
    let container = Container()
    container.register(Animal.self) { resolver in
        Fish(name: "joe")
    }
    let key = FactoryKey(productType: Animal.self)
    let result = container.factories.getValue(for: key) as? FactoryRegistration<Animal>
    let product = result?.factory.make(container)
    Task { @MainActor in
        #expect("joe" == product?.name)
    }
}

@Test func testMainActorClassRegistration() async throws {
    let container = Container()
    container.registerAsync(Animal.self) { resolver in
        await Pig(name: "joe")
    }
    let key = FactoryKey(productType: Animal.self)
    let result = container.factories.getValue(for: key) as? FactoryRegistration<Animal>
    let animal = await result?.factory.makeAsync(container)
    await MainActor.run {
        #expect("joe" == animal?.name)
    }
}
