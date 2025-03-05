// Mock Behavior for testing thread safety
class MockBehavior: Behavior {
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        // No action needed for this test
    }
}