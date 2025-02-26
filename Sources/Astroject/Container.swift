//
//  Container.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

// ✅ Registration
// ✅ Resolution
// TODO: InstanceStore

public class Container {
    var factories: ThreadSafeDictionary<FactoryKey, any FactoryRegistrable> = .init()
    
    public init() {}
    
    public func registerAsync<Product>(_ productType: Product.Type, name: String? = nil, factory block: @escaping (Resolver) async -> Product) {
        let factoryKey = FactoryKey(productType: productType, name: name)
        let factory = Factory.async(block)
        let registration = FactoryRegistration(factory: factory)
        factories.insert(registration, for: factoryKey)
    }
    
    public func register<Product>(_ productType: Product.Type, name: String? = nil, factory block: @escaping (Resolver) -> Product) {
        let factoryKey = FactoryKey(productType: productType, name: name)
        let factory = Factory.sync(block)
        let registration = FactoryRegistration(factory: factory)
        factories.insert(registration, for: factoryKey)
    }
}

extension Container: Resolver {
    public func resolve<Product>(_ productType: Product.Type, name: String?) -> Product? {
        let registration = registration(for: productType, with: name)
        let product = registration?.factory.make(self)
        return product
    }
    
    public func resolveAsync<Product>(_ productType: Product.Type, name: String?) async -> Product? {
        let registration = registration(for: productType, with: name)
        let product = await registration?.factory.makeAsync(self)
        return product
    }
    
    func registration<Product>(for productType: Product.Type, with name: String?) -> FactoryRegistration<Product>? {
        let factoryKey = FactoryKey(productType: productType, name: name)
        let registration = factories.getValue(for: factoryKey) as? FactoryRegistration<Product>
        return registration
    }
}
