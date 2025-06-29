//
//  MockPerformanceBehavior.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import AstrojectCore

// Mock Behavior for performance testing
class MockPerformanceBehavior: Behavior {
    func didResolve<Product>(
        type: Product.Type,
        to container: any Container,
        as registration: any Registrable,
        with name: String?
    ) {
        // Simulate some non-trivial work
        for _ in 0..<1_000 {
            _ = sin(Double.random(in: 0..<1))
        }
    }
    
    func didRegister<Product1, Product2>(
        type: Product1.Type,
        to container: any Container,
        as registration: any Registrable<Product2>,
        with name: String?
    ) {
        // Simulate some non-trivial work
        for _ in 0..<1_000 {
            _ = sin(Double.random(in: 0..<1))
        }
    }
}
