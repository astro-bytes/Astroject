//
//  Composite.swift
//  Astroject
//
//  Created by Porter McGary on 2/26/25.
//

import Foundation

/// A composite instance that manages a collection of instances.
public actor Composite<Product: Sendable>: Instance {
    /// An array of instances that this composite manages.
    var instances: [any Instance<Product>] = []
    
    /// Initializes a new Composite instance with the given array of instances.
    ///
    /// - Parameter instances: The array of instances to manage.
    public init(instances: [any Instance<Product>]) {
        self.instances = instances
    }
    
    /// Retrieves the first non-nil instance from the managed instances.
    ///
    /// - Returns: The first non-nil instance, or nil if none is found.
    public func get() async -> Product? {
        await instances.compactMap { await $0.get() }.first
    }
    
    /// Sets the given product on all managed instances.
    ///
    /// - Parameter product: The product to set.
    public func set(_ product: Product) async {
        await instances.forEach { await $0.set(product) }
    }
    
    /// Releases all managed instances.
    public func release() async {
        await instances.forEach { await $0.release() }
    }
}

extension Sequence {
    /// Asynchronously transforms each element of the sequence into a new value.
    ///
    /// - Parameter transform: An asynchronous closure that transforms an element into a new value.
    /// - Returns: An array containing the transformed values.
    func map<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
    
    /// Asynchronously transforms each element of the sequence into an optional value,
    /// and returns an array of the non-nil results.
    ///
    /// - Parameter transform: An asynchronous closure that transforms an element into an optional value.
    /// - Returns: An array containing the non-nil transformed values.
    func compactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            if let transformed = try await transform(element) {
                values.append(transformed)
            }
        }
        return values
    }
    
    /// Asynchronously performs the given closure for each element of the sequence.
    ///
    /// - Parameter body: An asynchronous closure that takes an element of the sequence as a parameter.
    func forEach(
        _ body: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await body(element)
        }
    }
}
