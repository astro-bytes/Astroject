//
//  Factory.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

enum Factory<Product> {
    typealias FactoryClosure = (Resolver) throws -> Product
    typealias AsyncFactoryClosure = (Resolver) async throws -> Product
    
    case sync(FactoryClosure)
    case async(AsyncFactoryClosure)
    
    var isSync: Bool {
        switch self {
        case .sync:
            true
        case .async:
            false
        }
    }
    
    var isAsync: Bool {
        !isSync
    }
    
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
    static func == (lhs: Factory<Product>, rhs: Factory<Product>) -> Bool {
        switch (lhs, rhs) {
        case (.async, .async),
            (.sync, .sync):
            true
        default:
            false
        }
    }
}
