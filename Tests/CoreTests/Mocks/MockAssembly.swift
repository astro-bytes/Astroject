// Mock Assembly for testing
class MockAssembly: Assembly {
    var assembleCalled = false
    var loadedCalled = false
    
    func assemble(container: Container) {
        assembleCalled = true
    }
    
    func loaded(resolver: Resolver) {
        loadedCalled = true
    }
}