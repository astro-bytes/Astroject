//
//  MockInstance.swift
//  Astroject
//
//  Created by Porter McGary on 5/24/25.
//

import Foundation
import AstrojectCore

struct MockInstance<Product>: Instance {
    var whenSet: () -> Void = {}
    var whenGet: () -> Product? = { nil }
    var whenRelease: () -> Void = {}
    
    func set(_ product: Product, for context: Context) {
        whenSet()
    }
    
    func get(for context: Context) -> Product? {
        whenGet()
    }
    
    func release(for context: Context?) {
        whenRelease()
    }
}
