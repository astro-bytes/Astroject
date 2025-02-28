//
//  Factory.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// Represents a factory for creating instances of a product.
enum Factory<Product> {
    /// A closure for synchronously creating a product instance.
    typealias FactoryClosure = (Resolver) throws -> Product
    /// A closure for asynchronously creating a product instance.
    typealias AsyncFactoryClosure = (Resolver) async throws -> Product
    
    /// A synchronous factory.
    case sync(FactoryClosure)
    /// An asynchronous factory.
    case async(AsyncFactoryClosure)
    
    /// Indicates whether the factory is synchronous.
    var isSync: Bool {
        switch self {
        case .sync:
            return true
        case .async:
            return false
        }
    }
    
    /// Indicates whether the factory is asynchronous.
    var isAsync: Bool {
        return !isSync
    }
    
    /// Creates a product instance synchronously.
    ///
    /// - Parameter resolver: The resolver to use for dependency resolution.
    /// - Returns: The created product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during creation, or `ResolutionError.asyncResolutionRequired` if called on an async factory.
    func make(_ resolver: Resolver) throws -> Product {
        switch self {
        case .sync(let closure):
            do {
                return try closure(resolver)
            } catch {
                throw ResolutionError.underlyingError(error)
            }
        case .async:
            throw ResolutionError.asyncResolutionRequired
        }
    }
    
    /// Creates a product instance asynchronously.
    ///
    /// - Parameter resolver: The resolver to use for dependency resolution.
    /// - Returns: The created product instance.
    /// - Throws: `ResolutionError.underlyingError` if an error occurs during creation.
    func makeAsync(_ resolver: Resolver) async throws -> Product {
        do {
            switch self {
            case .sync(let closure):
                return try closure(resolver)
            case .async(let closure):
                return try await closure(resolver)
            }
        } catch {
            throw ResolutionError.underlyingError(error)
        }
    }
}

extension Factory: Equatable where Product: Equatable {
    /// Checks if two factories are equal.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side factory.
    ///   - rhs: The right-hand side factory.
    /// - Returns: `true` if the factories are equal, `false` otherwise.
    static func == (lhs: Factory<Product>, rhs: Factory<Product>) -> Bool {
        switch (lhs, rhs) {
        case (.async, .async),
             (.sync, .sync):
            return true
        default:
            return false
        }
    }
}
