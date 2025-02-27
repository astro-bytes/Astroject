//
//  AstrojectError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur within the Astroject dependency injection container.
public enum AstrojectError: Error {
    /// Errors related to dependency resolution.
    case resolution(ResolutionError)
    /// Errors related to factory creation.
    case factory(FactoryError)
    /// Errors related to dependency registration.
    case registration(RegistrationError)
    /// Errors related to instance management.
    case instance(InstanceError)
    /// Errors that occur internally within the library.
    case internalError(Error)
}
