//
//  MockResolver.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// swiftlint:disable force_cast

// Mock Resolver for testing
class MockResolver: Resolver {
    var whenResolve: () throws -> Any = { 42 }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product, Argument>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product>(productType: Product.Type, name: String?) throws -> Product {
        try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        try whenResolve() as! Product
    }
}

// swiftlint:enable force_cast
