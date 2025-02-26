//
//  FactoryRegistration.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

struct FactoryRegistration<Product>: FactoryRegistrable {
    let factory: Factory<Product>
    
    init(factory: Factory<Product>) {
        self.factory = factory
    }
}
