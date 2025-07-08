//
//  ArgumentRegistration+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 6/27/25.
//

@testable import AstrojectCore

extension ArgumentRegistration {
    convenience init(
        name: String? = nil,
        factory: Factory<Product, Arguments>,
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
        factory: Factory<Product, Arguments>,
        isOverridable: Bool,
        argument: Argument,
        instance: any Instance<Product>
    ) {
        self.init(
            container: MockContainer(),
            key: RegistrationKey(factory: factory, name: name),
            factory: factory,
            isOverridable: isOverridable,
            argument: argument,
            instance: instance
        )
    }
}
