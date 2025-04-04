//
// Factory.swift
// Astroject
//
// Created by Porter McGary on 3/4/25.
//

import Foundation

/// A factory struct that encapsulates a closure for creating instances of a product type.
///
/// This struct is used to store and execute the logic for resolving dependencies and
/// creating objects within the dependency injection container.
public struct Factory<Product>: Equatable {
    /// Defines a type alias for the factory closure, which takes a `Resolver` and returns a `Product` asynchronously.
    public typealias Block = (Resolver) async throws -> Product
    
    /// A unique identifier for the factory, used for equality checks.
    private let id: UUID = UUID()
    /// The closure that creates the product instance.
    private let block: Block
    
    /// Initializes a new `Factory` instance with the given closure.
    ///
    /// - Parameter block: The closure that creates the product instance.
    public init(_ block: @escaping Block) {
        self.block = block
    }
    
    /// Executes the factory closure to create a product instance.
    ///
    /// - Parameter resolver: The `Resolver` used to resolve dependencies.
    /// - Returns: The created product instance.
    /// - Throws: Any error thrown by the factory closure.
    func callAsFunction(_ resolver: Resolver) async throws -> Product {
        try await block(resolver)
    }
    
    /// Checks if two `Factory` instances are equal based on their unique identifiers.
    ///
    /// - Parameters:
    ///     - lhs: The left-hand side `Factory` instance.
    ///     - rhs: The right-hand side `Factory` instance.
    /// - Returns: `true` if the factories are equal, `false` otherwise.
    public static func == (lhs: Factory, rhs: Factory) -> Bool {
        lhs.id == rhs.id
    }
}
