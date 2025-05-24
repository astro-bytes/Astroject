//
//  File.swift
//  Astroject
//
//  Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

struct MockRegistration<Product>: Registrable {
    typealias Action = () -> Void
    
    var whenAs: () -> MockRegistration<Product> = {
        .init(Product.self)
    }
    
    var whenAfterInit: () -> MockRegistration<Product> = {
        .init(Product.self)
    }
    
    var isOverridable: Bool = false
    
    init(_ type: Product.Type) {}
    init() {}
    
    func `as`(_ instance: any Instance<Product>) -> MockRegistration {
        whenAs()
    }
    
    func afterInit(perform action: () -> Void) -> MockRegistration {
        whenAs()
    }
}
