//
//  Container.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

// ✅ Registration
// ✅ Resolution
// ✅ InstanceStore
// TODO: Error Handling
// TODO: Write Unit Tests
// TODO: Is this robust and sufficient enough to support my needs?

public class Container {
    var factories: ThreadSafeDictionary<ProductKey, any Registrable> = .init()
    
    public init() {}
    
    @discardableResult
    public func registerAsync<Product>(_ productType: Product.Type, name: String? = nil, factory block: @escaping (Resolver) async -> Product) -> Registration<Product> {
        let factoryKey = ProductKey(productType: productType, name: name)
        let factory = Factory.async(block)
        let registration = Registration(factory: factory, container: self)
        factories.insert(registration, for: factoryKey)
        return registration
    }
    
    @discardableResult
    public func register<Product>(_ productType: Product.Type, name: String? = nil, factory block: @escaping (Resolver) -> Product) -> Registration<Product> {
        let factoryKey = ProductKey(productType: productType, name: name)
        let factory = Factory.sync(block)
        let registration = Registration(factory: factory, container: self)
        factories.insert(registration, for: factoryKey)
        return registration
    }
}

extension Container: Resolver {
    public func resolve<Product>(_ productType: Product.Type, name: String?) -> Product? {
        let registration = registration(for: productType, with: name)
        let product = registration?.resolve()
        return product
    }
    
    public func resolveAsync<Product>(_ productType: Product.Type, name: String?) async -> Product? {
        let registration = registration(for: productType, with: name)
        let product = await registration?.resolveAsync()
        return product
    }
    
    func registration<Product>(for productType: Product.Type, with name: String?) -> Registration<Product>? {
        let factoryKey = ProductKey(productType: productType, name: name)
        let registration = factories.getValue(for: factoryKey) as? Registration<Product>
        return registration
    }
}
