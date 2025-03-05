//
//  Factory.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation

public struct Factory<Product>: Equatable {
    public static func ==(lhs: Factory, rhs: Factory) -> Bool {
        lhs.id == rhs.id
    }
    
    public typealias Block = (Resolver) async throws -> Product
    
    private let id: UUID = UUID()
    private let block: Block
    
    public init(_ block: @escaping Block) {
        self.block = block
    }
    
    func callAsFunction(_ resolver: Resolver) async throws -> Product {
        try await block(resolver)
    }
}
