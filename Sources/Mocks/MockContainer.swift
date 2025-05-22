//
//  MockContainer.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable force_cast

class MockContainer: Container {
    var whenRegister: () throws -> Void = {}
    var whenResolve: () throws -> Any = { 42 }
    var whenIsRegister: () -> Bool = { true }
    var whenClear: () -> Void = {}
    var whenAdd: () -> Void = {}
    
    func register<Product>(
        productType: Product.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, any Resolver>
    ) throws -> any Registrable<Product> {
        try whenRegister()
        return MockRegistration<Product>()
    }
    
    func register<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument.Type,
        isOverridable: Bool,
        factory: Factory<Product, (any Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        try whenRegister()
        return MockRegistration<Product>()
    }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        try whenResolve() as! Product
    }
    
    func isRegistered<Product>(
        productType: Product.Type,
        with name: String?
    ) -> Bool {
        whenIsRegister()
    }
    
    func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool {
        whenIsRegister()
    }
    
    func clear() {
        whenClear()
    }
    
    func add(_ behavior: any Behavior) {
        whenAdd()
    }
}

// swiftlint:enable force_cast
