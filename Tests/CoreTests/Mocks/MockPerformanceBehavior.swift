//
//  MockPerformanceBehavior.swift
//  Astroject
//
//  Created by Porter McGary on 3/4/25.
//

import Foundation
import Core

// Mock Behavior for performance testing
class MockPerformanceBehavior: Behavior {
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: any Registrable<Product>,
        with name: String?
    ) {
        // Simulate some non-trivial work
        for _ in 0..<1_000 {
            _ = sin(Double.random(in: 0..<1))
        }
    }
}
