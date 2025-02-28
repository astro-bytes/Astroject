//
//  Registrable.swift
//  Astroject
//
//  Created by Porter McGary on 2/25/25.
//

import Foundation

/// A protocol defining a registrable component that can be resolved by a `Container`.
protocol Registrable {
    /// The type of product that this registrable component produces.
    associatedtype Product
    
    /// The factory used to create instances of the product.
    var factory: Factory<Product> { get }
    
    /// The instance management strategy for the product.
    var instance: any Instance<Product> { get }
    
    /// Indicates whether this registration can be overridden by another registration.
    var isOverridable: Bool { get }
}
