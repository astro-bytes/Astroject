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
// ✅ Error Handling
// ✅ Behaviors
// ✅ Assemblies
// TODO: Write Unit Tests

public class Container {
    var registrations: ThreadSafeDictionary<RegistrationKey, any Registrable> = .init()
    var resolvingKeys: Set<RegistrationKey> = .init()
    var behaviors: ThreadSafeArray<Behavior> = .init()
    
    public init() {}
    
    @discardableResult
    public func registerAsync<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        overridable: Bool = true,
        factory block: @escaping (Resolver) async throws -> Product
    ) throws -> Registration<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let factory = Factory.async(block)
        let registration = Registration(factory: factory, isOverridable: overridable)
        if let registration = registrations.getValue(for: key) {
            guard registration.isOverridable else {
                throw RegistrationError.alreadyRegistered
            }
            
            guard overridable else {
                throw RegistrationError.alreadyRegistered
            }
        }
        registrations.insert(registration, for: key)
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        return registration
    }
    
    @discardableResult
    public func register<Product>(
        _ productType: Product.Type,
        name: String? = nil,
        overridable: Bool = true,
        factory block: @escaping (Resolver) throws -> Product
    ) throws -> Registration<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let factory = Factory.sync(block)
        let registration = Registration(factory: factory, isOverridable: overridable)
        if let registration = registrations.getValue(for: key) {
            guard registration.isOverridable else {
                throw RegistrationError.alreadyRegistered
            }
            
            guard overridable else {
                throw RegistrationError.alreadyRegistered
            }
        }
        registrations.insert(registration, for: key)
        behaviors.forEach { $0.didRegister(type: productType, to: self, as: registration, with: name) }
        return registration
    }
    
    public func isRegistered<Product>(_ productType: Product.Type, with name: String?) -> Bool {
        let key = RegistrationKey(productType: productType, name: name)
        return registrations.contains(key)
    }
    
    public func clear() {
        registrations.removeAll()
    }
    
    public func add(_ behavior: Behavior) {
        behaviors.append(behavior)
    }
}

extension Container: Resolver {
    public func resolve<Product>(_ productType: Product.Type, name: String?) throws -> Product {
        defer { removeRegistrationKey(for: productType, with: name) }
        let registration = try findRegistration(for: productType, with: name)
        let product = try registration.resolve(self)
        return product
    }
    
    public func resolveAsync<Product>(_ productType: Product.Type, name: String?) async throws -> Product {
        defer { removeRegistrationKey(for: productType, with: name) }
        let registration = try findRegistration(for: productType, with: name)
        let product = try await registration.resolveAsync(self)
        return product
    }
}

extension Container {
    func findRegistration<Product>(for productType: Product.Type, with name: String?) throws -> Registration<Product> {
        let key = RegistrationKey(productType: productType, name: name)
        let result = resolvingKeys.insert(key)
        guard result.inserted else {
            resolvingKeys.removeAll()
            throw ResolutionError.circularDependencyDetected
        }
        guard let registration = registrations.getValue(for: key) as? Registration<Product>
        else { throw ResolutionError.noRegistrationFound }
        return registration
    }
    
    func removeRegistrationKey<Product>(for productType: Product.Type, with name: String?) {
        let key = RegistrationKey(productType: productType, name: name)
        resolvingKeys.remove(key)
    }
}
