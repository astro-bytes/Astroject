//
//  MockResolver.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// Mock Resolver for testing
class MockResolver: Resolver {
    let error = NSError(domain: "Test", code: 1)
    
    func resolve<Product>(_ productType: Product.Type, name: String?) async throws -> Product {
        if productType == Int.self {
            // swiftlint:disable:next force_cast
            return 42 as! Product
        } else if productType == String.self {
            // swiftlint:disable:next force_cast
            return "Test String" as! Product
        } else {
            throw error
        }
    }
    
    func resolve<Product, Argument>(_ productType: Product.Type, name: String?, argument: Argument) async throws -> Product {
        if productType == Int.self {
            // swiftlint:disable:next force_cast
            return 42 as! Product
        } else if productType == String.self {
            // swiftlint:disable:next force_cast
            return "Test String" as! Product
        } else {
            throw error
        }
    }
}
