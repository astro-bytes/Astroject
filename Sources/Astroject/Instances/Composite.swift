//
//  Composite.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

public class Composite<Product>: Instance {
    var instances: [any Instance<Product>] = []
    
    public init(instances: [any Instance<Product>]) {
        self.instances = instances
    }
    
    public func get() -> Product? {
        instances.compactMap { $0.get() }.first
    }
    
    public func set(_ product: Product) {
        instances.forEach { $0.set(product) }
    }
    
    public func release() {
        instances.forEach { $0.release() }
    }
}
