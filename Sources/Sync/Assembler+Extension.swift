//
// Assembler+Extension.swift
// Astroject
//
// Created by Porter McGary on 5/21/25.
//

import Foundation
import AstrojectCore

/// Extension providing convenience initializers for `Assembler`.
///
/// These initializers streamline common scenarios by allowing quick construction
/// of an `Assembler` with a default or custom container.
public extension Assembler {
    
    /// Creates an `Assembler` using the specified container.
    ///
    /// This initializer is useful when you want to manually configure the container
    /// or resolve dependencies without registering any assemblies immediately.
    ///
    /// - Parameter container: The `Container` instance to associate with the assembler.
    ///   Defaults to a new instance of `SyncContainer`.
    convenience init(_ container: Container = SyncContainer()) {
        self.init(container: container)
    }
}
