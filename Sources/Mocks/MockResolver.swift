//
//  MockResolver.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// Mock Resolver for testing
class MockResolver<P>: Resolver {
    var whenResolve: () throws -> P = { throw MockError() }
    
    func resolve<Product>(
        productType: Product.Type,
        name: String?
    ) async throws -> Product {
        guard Product.self == P.self else {
            throw MockError()
        }
        return try whenResolve() as! Product
    }
    
    func resolve<Product, Argument>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) async throws -> Product {
        guard Product.self == P.self else {
            throw MockError()
        }
        return try whenResolve() as! Product
    }
    
    func resolve<Product>(productType: Product.Type, name: String?) throws -> Product {
        guard Product.self == P.self else {
            throw MockError()
        }
        return try whenResolve() as! Product
    }
    
    func resolve<Product, Argument: Hashable>(
        productType: Product.Type,
        name: String?,
        argument: Argument
    ) throws -> Product {
        guard Product.self == P.self else {
            throw MockError()
        }
        return try whenResolve() as! Product
    }
}
