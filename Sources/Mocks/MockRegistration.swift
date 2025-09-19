//
//  File.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

struct MockRegistration<Product>: Registrable {
    typealias Action = () -> Void
    
    var whenAs: () -> MockRegistration<Product> = {
        .init(Product.self)
    }
    
    var whenAfterInit: () -> MockRegistration<Product> = {
        .init(Product.self)
    }
    
    var whenKey: () -> RegistrationKey = {
        RegistrationKey(factoryType: Int.self, productType: Product.self)
    }
    
    var whenImplements: () -> Self = {
        .init(Product.self)
    }
    
    var whenResolve: () throws -> Product = {
        throw MockError()
    }
    
    var whenRelease: () throws -> Void = {
        throw MockError()
    }
    
    var isOverridable: Bool = false
    var argumentType: Any.Type = Empty.self
    var key: RegistrationKey = .init(factoryType: Int.self, productType: Product.self)
    
    init(_ type: Product.Type) {}
    init() {}
    init(isOverridable: Bool, key: RegistrationKey) {
        self.isOverridable = isOverridable
        self.key = key
    }
    
    func `as`(_ instance: any Instance<Product>.Type) -> MockRegistration {
        whenAs()
    }
    
    func afterInit(perform action: () -> Void) -> MockRegistration {
        whenAfterInit()
    }
    
    func key(with name: String?) -> RegistrationKey {
        whenKey()
    }
    
    func implements<T>(_ type: T.Type) -> MockRegistration<Product> {
        whenImplements()
    }
    
    func resolve<Argument>(container: any Container, argument: Argument, in context: any Context) throws -> Product {
        try whenResolve()
    }

    func release<Argument>(with: Argument, in: any Context) throws {
        try whenRelease()
    }
}
