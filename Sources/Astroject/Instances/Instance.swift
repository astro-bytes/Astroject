//
//  Instance.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

public protocol Instance<Product> {
    associatedtype Product
    
    func get() -> Product?
    func set(_ product: Product)
    func release()
}
