//
//  Factory.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

enum Factory<Product> {
    case sync((Resolver) -> Product)
    case async((Resolver) async -> Product)
    
    var isSync: Bool {
        switch self {
        case .sync:
            return true
        case .async:
            return false
        }
    }
    
    var isAsync: Bool {
        return !isSync
    }
    
    func make(_ resolver: Resolver) -> Product {
        switch self {
        case .sync(let closure):
            closure(resolver)
        case .async:
            fatalError("Factory Method is Async. Try calling the async version of this method.")
        }
    }
    
    func makeAsync(_ resolver: Resolver) async -> Product {
        switch self {
        case .sync(let closure):
            closure(resolver)
        case .async(let closure):
            await closure(resolver)
        }
    }
}
