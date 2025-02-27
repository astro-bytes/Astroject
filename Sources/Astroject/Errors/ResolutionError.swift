//
//  ResolutionError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency resolution.
public enum ResolutionError: Error {
    /// A dependency is requested but not registered.
    case noRegistrationFound
    /// Circular dependency detected.
    case circularDependency
    /// Calling a sync function when an async function should be called instead.
    case asyncResolutionRequired
}
