//
//  MockContainer.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

final class MockContainer: Container, @unchecked Sendable {
    var callsRegister: Bool = false
    var callsResolve: Bool = false
    var callsIsRegister: Bool = false
    var callsClear: Bool = false
    var callsAdd: Bool = false
    var callsForward: Bool = false
    
    var whenRegister: () throws -> Void = {}
    var whenResolve: () throws -> Any = { 42 }
    var whenIsRegister: () -> Bool = { true }
    var whenClear: () -> Void = {}
    var whenAdd: () -> Void = {}
    var whenForward: () -> Void = {}
    
    func register<Product>(
        productType: Product.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, any Resolver>
    ) throws -> any Registrable<Product> {
        callsRegister = true
        try whenRegister()
        return Registration(
            container: self,
            key: RegistrationKey(factory: factory, name: name),
            factory: factory,
            isOverridable: isOverridable,
            instanceType: MockInstance.self
        )
    }
    
    func register<Product, Argument: Hashable>(
        productType: Product.Type,
        argumentType: Argument.Type,
        name: String?,
        isOverridable: Bool,
        factory: Factory<Product, (any Resolver, Argument)>
    ) throws -> any Registrable<Product> {
        callsRegister = true
        try whenRegister()
        return ArgumentRegistration(
            container: self,
            key: RegistrationKey(factory: factory, name: name),
            factory: factory,
            isOverridable: isOverridable,
            instanceType: MockInstance.self
        )
    }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product {
        callsResolve = true
        return try whenResolve() as! Product
    }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) throws -> Product {
        callsResolve = true
        return try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        callsResolve = true
        return try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        callsResolve = true
        return try whenResolve() as! Product
    }
    
    func isRegistered<Product>(
        productType: Product.Type,
        with name: String?
    ) -> Bool {
        callsIsRegister = true
        return whenIsRegister()
    }
    
    func isRegistered<Product, Argument: Hashable>(
        productType: Product.Type,
        with name: String?,
        and argumentType: Argument.Type
    ) -> Bool {
        callsIsRegister = true
        return whenIsRegister()
    }
    
    func clear() {
        callsClear = true
        whenClear()
    }
    
    func add(_ behavior: any Behavior) {
        callsAdd = true
        whenAdd()
    }
    
    func forward<Conformance, Product>(
        _ type: Conformance.Type,
        to registration: any Registrable<Product>
    ) {
        callsForward = true
        whenForward()
    }
}
