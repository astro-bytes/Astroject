//
//  ResolutionError.swift
//  Astroject
//
//  Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency resolution.
public enum ResolutionError: LocalizedError {
    // TODO: Comment
    case containerDeallocated
    /// A dependency is requested but not registered.
    case noRegistrationFound
    /// Circular dependency detected.
    case circularDependencyDetected
    /// An error that occurred within the factory closure.
    case underlyingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .containerDeallocated:
            // TODO: Implement
            ""
        case .noRegistrationFound:
            "No registration found for the requested dependency."
        case .circularDependencyDetected:
            "A circular dependency was detected."
        case .underlyingError(let error):
            "An error occurred within the factory closure: \(error.localizedDescription)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .containerDeallocated:
            // TODO: Implement
            ""
        case .noRegistrationFound:
            "Register the dependency before attempting to resolve it."
        case .circularDependencyDetected:
            "Review your dependency graph to eliminate circular dependencies."
        case .underlyingError:
            "Inspect the underlying error for more details."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .containerDeallocated:
            // TODO: Implement
            ""
        case .noRegistrationFound:
            "Use the `register` or `registerAsync` method to register the dependency."
        case .circularDependencyDetected:
            "Break the circular dependency by introducing an abstraction or using a different dependency injection pattern or by using `postInitAction` to initialize cyclical dependencies."
        case .underlyingError:
            "Check the factory closure for errors and ensure that it's correctly implemented."
        }
    }
}

extension ResolutionError: Equatable {
    public static func == (lhs: ResolutionError, rhs: ResolutionError) -> Bool {
        switch (lhs, rhs) {
        case (.noRegistrationFound, .noRegistrationFound),
             (.circularDependencyDetected, .circularDependencyDetected),
             (.containerDeallocated, .containerDeallocated):
            true
        case (.underlyingError, .underlyingError):
            String(describing: lhs) == String(describing: rhs)
        default:
            false
        }
    }
}
