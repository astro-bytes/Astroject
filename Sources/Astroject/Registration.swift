//
//  Registration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

public class Registration<Product>: Registrable {
    let factory: Factory<Product>
    
    var instance: any Instance<Product>
    
    weak var container: Container?
    
    init(factory: Factory<Product>,
         instance: any Instance<Product> = Prototype<Product>(),
         container: Container) {
        self.factory = factory
        self.instance = instance
        self.container = container
    }
    
    func resolve() -> Product? {
        if let product = self.instance.get() {
            return product
        } else {
            guard let container else { return nil }
            let product: Product
            switch factory {
            case .async:
                return nil
            case .sync(let closure):
                product = closure(container)
            }
            self.instance.set(product)
            return product
        }
    }
    
    func resolveAsync() async -> Product? {
        if let product = self.instance.get() {
            return product
        } else {
            guard let container else { return nil }
            let product: Product
            switch factory {
            case .async(let closure):
                product = await closure(container)
            case .sync(let closure):
                product = closure(container)
            }
            self.instance.set(product)
            return product
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
    public func weakScope() -> Self {
        self.scope(Weak())
    }
    
    @discardableResult
    public func prototypeScope() -> Self {
        self.scope(Prototype())
    }
}
