//
//  Assembly.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// A protocol defining an assembly that configures dependencies in a `Container`.
public protocol Assembly {
    /// Configures dependencies within the provided `Container`.
    ///
    /// - Parameter container: The `Container` instance to configure.
    func assemble(container: Container)
    
    /// Called after the assembly has been loaded into the `Container`.
    ///
    /// - Parameter resolver: The `Resolver` instance providing access to the assembled dependencies.
    func loaded(resolver: Resolver)
}

public extension Assembly {
    /// Default implementation of `loaded(resolver:)`, which does nothing.
    ///
    /// - Parameter resolver: The `Resolver` instance (unused in the default implementation).
    func loaded(resolver: Resolver) {}
}
