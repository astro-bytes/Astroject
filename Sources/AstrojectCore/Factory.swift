//
// Factory.swift
// Astroject
//
// Created by Porter McGary on 3/4/25.
//

import Foundation

// TODO: Comment
public struct Factory<Product, Arguments>: Equatable {
    // TODO: Comment
    public typealias AsyncBlock = (Arguments) async throws -> Product
    // TODO: Comment
    public typealias SyncBlock = (Arguments) throws -> Product
    
    // TODO: Comment
    public enum Block {
        // TODO: Comment
        case sync(SyncBlock)
        // TODO: Comment
        case async(AsyncBlock)
        
        // TODO: Comment
        func callAsFunction(_ arguments: Arguments) async throws -> Product {
            switch self {
            case .sync(let syncBlock):
                try syncBlock(arguments)
            case .async(let asyncBlock):
                try await asyncBlock(arguments)
            }
        }
        
        // TODO: Comment
        func callAsFunction(_ arguments: Arguments) throws -> Product {
            switch self {
            case .sync(let syncBlock):
                try syncBlock(arguments)
            case .async:
                throw AstrojectError.misplacedAsyncCall
            }
        }
    }
    
    /// A unique identifier for the factory, used for equality checks.
    private let id: UUID = UUID()
    /// The closure that creates the product instance.
    private let block: Block
    
    // TODO: Comment
    public init(_ block: @escaping AsyncBlock) {
        self.block = .async(block)
    }
    
    // TODO: Comment
    public init(_ block: @escaping SyncBlock) {
        self.block = .sync(block)
    }
    
    // TODO: Comment
    public init(_ block: Block) {
        self.block = block
    }
    
    /// Executes the factory closure to create a product instance.
    ///
    /// - parameter arguments: The `Argument` used in the block of code
    /// - Returns: The created product instance.
    /// - Throws: Any error thrown by the factory closure.
    func callAsFunction(_ arguments: Arguments) async throws -> Product {
        try await block(arguments)
    }
    
    // TODO: Comment
    func callAsFunction(_ arguments: Arguments) throws -> Product {
        try block(arguments)
    }
    
    /// Checks if two `Factory` instances are equal based on their unique identifiers.
    ///
    /// - parameter lhs: The left-hand side `Factory` instance.
    /// - parameter rhs: The right-hand side `Factory` instance.
    /// - Returns: `true` if the factories are equal, `false` otherwise.
    public static func == (lhs: Factory, rhs: Factory) -> Bool {
        lhs.id == rhs.id
    }
}

// TODO: Comment
extension Factory where Arguments == Resolver {
    // TODO: Comment
    public init(_ block: @escaping (Resolver) async throws -> Product) {
        self.block = .async(block)
    }
    
    // TODO: Comment
    public init(_ block: @escaping (Resolver) throws -> Product) {
        self.block = .sync(block)
    }
    
    // TODO: Comment
    public init(_ block: @escaping () async throws -> Product) {
        self.block = .async({ _ in try await block() })
    }
    
    // TODO: Comment
    public init(_ block: @escaping () throws -> Product) {
        self.block = .sync({ _ in try block() })
    }
}
