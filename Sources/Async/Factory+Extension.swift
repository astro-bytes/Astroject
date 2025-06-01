//
//  Factory+Extension.swift
//  Astroject
//
//  Created by Porter McGary on 5/22/25.
//

import Foundation
import AstrojectCore

/// Extension for `Factory` where `Arguments` is `Resolver`.
///
/// This extension provides convenience initializers for creating `Factory` instances
/// specifically for asynchronous operations where the factory block takes a `Resolver`
/// or no arguments.
public extension Factory where Arguments == Resolver {
    /// Initializes a `Factory` with an asynchronous block that takes a `Resolver`.
    ///
    /// This initializer simplifies the creation of factories for dependencies that need
    /// access to the resolver itself during their asynchronous construction.
    ///
    /// - Parameter block: An `async throws` closure that accepts a `Resolver` and
    ///                    returns the `Product` instance.
    init(_ block: @escaping (Resolver) async throws -> Product) {
        self.init(.async(block))
    }

    /// Initializes a `Factory` with an asynchronous block that takes no arguments.
    ///
    /// This initializer is for straightforward asynchronous dependency creation where
    /// the factory does not require the `Resolver` explicitly to build the `Product`.
    ///
    /// - Parameter block: An `async throws` closure that returns the `Product` instance.
    init(_ block: @escaping () async throws -> Product) {
        self.init(.async({ _ in try await block() }))
    }
}

/// Extension for `Factory` with general `Arguments`.
///
/// This extension provides convenience initializers for creating `Factory` instances
/// for asynchronous operations where the factory block might take both a `Resolver`
/// and a custom `Argument`, or just the `Argument`.
public extension Factory {
    /// Initializes a `Factory` with an asynchronous block that takes both a `Resolver` and an `Argument`.
    ///
    /// This initializer simplifies the creation of factories for dependencies that require
    /// both access to the resolver and a specific argument during their asynchronous construction.
    ///
    /// - Parameter block: An `async throws` closure that accepts a `Resolver` and an `Argument`,
    ///                    then returns the `Product` instance.
    init<Argument>(
        _ block: @escaping (Resolver, Argument) async throws -> Product
    ) where Arguments == (Resolver, Argument) {
        let block = Factory<Product, (Resolver, Argument)>.Block.async(block)
        self.init(block)
    }

    /// Initializes a `Factory` with an asynchronous block that takes only an `Argument`.
    ///
    /// This initializer is for asynchronous dependency creation where the product's instance
    /// depends solely on an external argument and does not require the `Resolver` for its construction.
    ///
    /// - Parameter block: An `async throws` closure that accepts an `Argument` and
    ///                    returns the `Product` instance.
    init<Argument>(
        _ block: @escaping (Argument) async throws -> Product
    ) where Arguments == (Resolver, Argument) {
        let block = Factory<Product, (Resolver, Argument)>.Block.async({ _, argument in
            try await block(argument)
        })

        self.init(block)
    }
}
