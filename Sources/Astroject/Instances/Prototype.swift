//
//  Prototype.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

public class Prototype<Product>: Instance {
    public init() {}
    
    public func get() -> Product? { nil }
    public func set(_ product: Product) {}
    public func release() {}
}
