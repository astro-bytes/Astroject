//
// Assembler+Extension.swift
// Astroject
//
// Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

/// Extension providing convenience initializers for `Assembler` using an asynchronous container.
///
/// These initializers allow quick construction of an `Assembler` with a default or custom
/// asynchronous container.
public extension Assembler {
    
    /// Creates an `Assembler` using the specified asynchronous container.
    ///
    /// This initializer is useful when you want to manually configure the container
    /// or resolve dependencies asynchronously without registering any assemblies immediately.
    ///
    /// - Parameter container: The `Container` instance to associate with the assembler.
    ///   Defaults to a new instance of `AsyncContainer`.
    convenience init(_ container: Container = AsyncContainer()) {
        self.init(container: container)
    }
}
