//
//  Registration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

public class Registration<Product>: Registrable {
    public typealias Action = (Resolver, Product) throws -> Void
    
    let factory: Factory<Product>
    
    var actions: [Action] = []
    var instance: any Instance<Product>
    var isOverridable: Bool
    
    init(factory: Factory<Product>,
         isOverridable: Bool,
         instance: any Instance<Product> = Prototype<Product>()
    ) {
        self.factory = factory
        self.isOverridable = isOverridable
        self.instance = instance
    }
    
    func resolve(_ container: Container) throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            let product: Product
            switch factory {
            case .async:
                throw ResolutionError.asyncResolutionRequired
            case .sync(let closure):
                product = try closure(container)
            }
            self.instance.set(product)
            try runActions(container, product: product)
            return product
        }
    }
    
    func resolveAsync(_ container: Container) async throws -> Product {
        if let product = self.instance.get() {
            return product
        } else {
            let product: Product
            switch factory {
            case .async(let closure):
                product = try await closure(container)
            case .sync(let closure):
                product = try closure(container)
            }
            self.instance.set(product)
            try runActions(container, product: product)
            return product
        }
    }
    
    func runActions(_ container: Container, product: Product) throws {
        do {
            try actions.forEach { try $0(container, product) }
        } catch {
            throw ResolutionError.underlyingError(error)
        }
    }
    
    @discardableResult
    public func scope(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    @discardableResult
    public func singletonScope() -> Self {
        self.scope(Singleton())
    }
    
    @discardableResult
    public func weakScope() -> Self where Product: AnyObject {
        self.scope(Weak())
    }
    
    @discardableResult
    public func prototypeScope() -> Self {
        self.scope(Prototype())
    }
    
    @discardableResult
    public func postInitAction(_ action: @escaping Action) -> Self {
        actions.append(action)
        return self
    }
}

extension Registration: Equatable where Product: Equatable {
    public static func == (lhs: Registration<Product>, rhs: Registration<Product>) -> Bool {
        lhs.instance.get() == rhs.instance.get() && lhs.isOverridable == rhs.isOverridable && lhs.factory == rhs.factory
    }
}
