//
//  Weak.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

public class Weak<Product>: Instance {
    var product: Product?
    
    public init() {}
    
    public func get() -> Product? {
        self.product
    }
    
    public func set(_ product: Product) {
        self.product = product
    }
    
    public func release() {
        self.product = nil
    }
}
