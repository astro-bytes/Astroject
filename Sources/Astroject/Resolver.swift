//
//  Resolver.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

public protocol Resolver {
    func resolve<Product>(_ productType: Product.Type) -> Product?
    func resolve<Product>(_ productType: Product.Type, name: String?) -> Product?
    
    func resolveAsync<Product>(_ productType: Product.Type) async -> Product?
    func resolveAsync<Product>(_ productType: Product.Type, name: String?) async -> Product?
}

public extension Resolver {
    func resolve<Product>(_ productType: Product.Type) -> Product? {
        resolve(productType, name: nil)
    }
    
    func resolveAsync<Product>(_ productType: Product.Type) async -> Product? {
        await resolveAsync(productType, name: nil)
    }
}
