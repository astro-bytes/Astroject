//
//  MockInstance.swift
//  Astroject
//
//  Created by Porter McGary on 5/24/25.
//

import Foundation
import AstrojectCore

class MockInstance<Product>: Instance {
    var setCount = 0
    var getCount = 0
    var releaseCount = 0
    
    var calledSet = false
    var calledGet = false
    var calledRelease = false
    
    var whenSet: () -> Void = {}
    var whenGet: () -> Product? = { nil }
    var whenRelease: () -> Void = {}
    
    required init() {}
    
    init(
        whenSet: @escaping () -> Void = {},
        whenGet: @escaping () -> Product? = { nil },
        whenRelease: @escaping () -> Void = {}
    ) {
        self.whenSet = whenSet
        self.whenGet = whenGet
        self.whenRelease = whenRelease
    }
    
    func set(_ product: Product, for context: any Context) {
        setCount += 1
        calledSet = true
        whenSet()
    }
    
    func get(for context: any Context) -> Product? {
        getCount += 1
        calledGet = true
        return whenGet()
    }
    
    func release(for context: (any Context)?) {
        releaseCount += 1
        calledRelease = true
        whenRelease()
    }
}
