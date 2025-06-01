//
// Factory.swift
// Astroject
//
// Created by Porter McGary on 3/4/25.
//

import Foundation

/// A generic structure that encapsulates a closure for creating product instances.
///
/// `Factory` supports both synchronous and asynchronous creation of products,
/// making it adaptable for various dependency resolution scenarios. It also provides
/// a mechanism for equality checking based on a unique identifier.
public struct Factory<Product, Arguments>: Equatable {
    /// A type alias for an asynchronous factory block.
    /// This block takes `Arguments` and asynchronously throws an error or returns a `Product`.
    public typealias AsyncBlock = (Arguments) async throws -> Product
    /// A type alias for a synchronous factory block.
    /// This block takes `Arguments` and synchronously throws an error or returns a `Product`.
    public typealias SyncBlock = (Arguments) throws -> Product
    
    /// An enumeration representing the underlying type of the factory block.
    ///
    /// This allows `Factory` to encapsulate either a synchronous or an asynchronous closure.
    public enum Block {
        /// Represents a synchronous factory closure.
        case sync(SyncBlock)
        /// Represents an asynchronous factory closure.
        case async(AsyncBlock)
        
        /// Allows the `Block` enum to be called directly as an asynchronous function.
        ///
        /// This method dispatches to either the `syncBlock` or `asyncBlock` based on the
        /// encapsulated type, wrapping the synchronous call in an `async` context.
        ///
        /// - parameter arguments: The arguments to pass to the factory block.
        /// - Returns: The created product instance.
        /// - Throws: Any error thrown by the underlying factory closure.
        func callAsFunction(_ arguments: Arguments) async throws -> Product {
            switch self {
            case .sync(let syncBlock):
                try syncBlock(arguments)
            case .async(let asyncBlock):
                try await asyncBlock(arguments)
            }
        }
        
        /// Allows the `Block` enum to be called directly as a synchronous function.
        ///
        /// This method executes the `syncBlock` directly. If the `Block` encapsulates
        /// an `asyncBlock`, it throws an `AstrojectError.invalidFactory` because
        /// an asynchronous factory cannot be resolved synchronously.
        ///
        /// - parameter arguments: The arguments to pass to the factory block.
        /// - Returns: The created product instance.
        /// - Throws: Any error thrown by the underlying synchronous factory closure, or
        ///           `AstrojectError.invalidFactory` if an asynchronous factory is called synchronously.
        func callAsFunction(_ arguments: Arguments) throws -> Product {
            switch self {
            case .sync(let syncBlock):
                try syncBlock(arguments)
            case .async:
                throw AstrojectError.invalidFactory
            }
        }
    }
    
    /// A unique identifier for the factory, used for equality checks.
    let id: UUID = .init()
    /// The closure that creates the product instance.
    let block: Block
    
    /// Initializes a new `Factory` instance with a given `Block`.
    ///
    /// - parameter block: The `Block` (either `.sync` or `.async`) that defines
    ///                    how the product instance will be created.
    public init(_ block: Block) {
        self.block = block
    }
    
    /// Executes the factory closure to create a product instance asynchronously.
    ///
    /// This method provides the primary way to invoke the factory, supporting both
    /// synchronous and asynchronous underlying blocks by awaiting the result.
    ///
    /// - parameter arguments: The `Arguments` to be passed to the factory block.
    /// - Returns: The created product instance.
    /// - Throws: Any error thrown by the factory closure.
    public func callAsFunction(_ arguments: Arguments) async throws -> Product {
        try await block(arguments)
    }
    
    /// Executes the factory closure to create a product instance synchronously.
    ///
    /// This method attempts to execute the factory synchronously. If the underlying
    /// `Block` is asynchronous, it will throw an `AstrojectError.invalidFactory`.
    ///
    /// - parameter arguments: The `Arguments` to be passed to the factory block.
    /// - Returns: The created product instance.
    /// - Throws: Any error thrown by the factory closure, or `AstrojectError.invalidFactory`
    ///           if an asynchronous factory is called synchronously.
    public func callAsFunction(_ arguments: Arguments) throws -> Product {
        try block(arguments)
    }
    
    /// Checks if two `Factory` instances are equal based on their unique identifiers.
    ///
    /// This comparison allows for stable equality checks of factories even if their
    /// underlying closures are syntactically identical but represent different instances.
    ///
    /// - parameter lhs: The left-hand side `Factory` instance.
    /// - parameter rhs: The right-hand side `Factory` instance.
    /// - Returns: `true` if the factories are equal, `false` otherwise.
    public static func == (lhs: Factory, rhs: Factory) -> Bool {
        lhs.id == rhs.id
    }
}
