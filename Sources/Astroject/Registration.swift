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
    
    @discardableResult
    public func scope(_ instance: any Instance<Product>) -> Self {
        self.instance = instance
        return self
    }
    
    @discardableResult
    public func singletonScope() -> Self {
        scope(Singleton())
    }
    
    @discardableResult
    public func weakScope() -> Self {
        scope(Weak())
    }
}
