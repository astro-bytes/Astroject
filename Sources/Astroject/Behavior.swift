//
//  Behavior.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Protocol for adding functionality to the container
public protocol Behavior: Sendable {
    func didRegister<Product>(
        type: Product.Type,
        to container: Container,
        as registration: Registration<Product>,
        with name: String?
    )
}
