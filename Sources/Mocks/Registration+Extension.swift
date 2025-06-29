//
//  Registration+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 6/27/25.
//

@testable import AstrojectCore

extension Registration {
    convenience init(
        name: String? = nil,
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instanceType: any Instance<Product>.Type
    ) {
        self.init(
            container: MockContainer(),
            key: RegistrationKey(factory: factory, name: name),
            factory: factory,
            isOverridable: isOverridable,
            instanceType: instanceType
        )
    }
    
    convenience init(
        name: String? = nil,
        factory: Factory<Product, Resolver>,
        isOverridable: Bool,
        instance: any Instance<Product>
    ) {
        self.init(
            container: MockContainer(),
            key: RegistrationKey(factory: factory, name: name),
            factory: factory,
            isOverridable: isOverridable,
            instance: instance
        )
    }
}
