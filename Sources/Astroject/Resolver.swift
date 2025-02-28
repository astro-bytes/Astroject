//
//  Resolver.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

public protocol Resolver {
    func resolve<Product>(_ productType: Product.Type) throws -> Product
    func resolve<Product>(_ productType: Product.Type, name: String?) throws -> Product
    
    func resolveAsync<Product>(_ productType: Product.Type) async throws -> Product
    func resolveAsync<Product>(_ productType: Product.Type, name: String?) async throws -> Product
}

public extension Resolver {
    func resolve<Product>(_ productType: Product.Type) throws -> Product {
        try resolve(productType, name: nil)
    }
    
    func resolveAsync<Product>(_ productType: Product.Type) async throws -> Product {
        try await resolveAsync(productType, name: nil)
    }
}
