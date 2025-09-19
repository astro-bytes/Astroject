//
//  DisposableSingleton.swift
//  Astroject
//
//  Created by Porter McGary on 9/18/25.
//

import Foundation

/// A disposable singleton instance that creates and stores a single instance of the product.
///
/// The `DisposableSingleton` class implements the `Instance` protocol and represents a 
/// singleton scope for dependency injection. It ensures that only one instance of the 
/// product is created and stored throughout the application's lifecycle until disposed 
/// of and another is created
public class DisposableSingleton<Product>: Instance {
    /// The stored product instance.
    private(set) var product: Product?
    
    /// Initializes a new `DisposableSingleton` instance.
    public required init() {}
    
    public func get(for: any Context) -> Product? {
        self.product
    }
    
    public func set(_ product: Product, for: any Context) {
        guard self.product == nil else { return }
        self.product = product
    }
    
    public func release(for: (any Context)?) {
        product = nil
    }
}
