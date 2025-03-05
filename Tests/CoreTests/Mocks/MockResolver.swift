// Mock Resolver for testing
class MockResolver: Resolver {
    let error = NSError(domain: "Test", code: 1)
    
    func resolve<Product>(_ productType: Product.Type, name: String?) async throws -> Product {
        if productType == Int.self {
            return 42 as! Product
        } else if productType == String.self {
            return "Test String" as! Product
        } else {
            throw error
        }
    }
}