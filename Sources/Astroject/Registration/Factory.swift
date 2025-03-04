//
//  Factory.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a factory for creating instances of a product.
//struct Factory<Product> {
//    /// A closure for synchronously creating a product instance.
//    typealias FactoryClosure = @Sendable (Resolver) async throws -> Product
//    
//    var block: FactoryClosure
//    
//    init(_ block: @escaping FactoryClosure) {
//        self.block = block
//    }
//    
//    /// Creates a product instance.
//    ///
//    /// - Parameter resolver: The resolver to use for dependency resolution.
//    /// - Returns: The created product instance.
//    /// - Throws: `ResolutionError.underlyingError` if an error occurs during creation, or `ResolutionError.asyncResolutionRequired` if called on an async factory.
//    func make(_ resolver: Resolver) async throws -> Product {
//        do {
//            return try await block(resolver)
//        } catch {
//            throw ResolutionError.underlyingError(error)
//        }
//    }
//}
