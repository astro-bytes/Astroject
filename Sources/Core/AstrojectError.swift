//
// AstrojectError.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency registration and resolution.
public enum AstrojectError<Product>: LocalizedError {
    /// A registration is attempted with a ProductKey that already exists.
    case alreadyRegistered(type: Product.Type, name: String? = nil)
    /// A dependency is requested but not registered.
    case noRegistrationFound
    /// Circular dependency detected.
    case circularDependencyDetected
    /// An error that occurred within the factory closure.
    case underlyingError(Error)

    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered:
            return "A registration with the same ProductKey already exists."
        case .noRegistrationFound:
            return "No registration found for the requested dependency."
        case .circularDependencyDetected:
            return "A circular dependency was detected."
        case .underlyingError(let error):
            return "An error occurred within the factory closure: \(error.localizedDescription)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .alreadyRegistered:
            return "Attempting to register a dependency with a ProductKey that has already been used."
        case .noRegistrationFound:
            return "Register the dependency before attempting to resolve it."
        case .circularDependencyDetected:
            return "Review your dependency graph to eliminate circular dependencies."
        case .underlyingError:
            return "Inspect the underlying error for more details."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .alreadyRegistered:
            return "Use a different ProductKey or remove the existing registration before registering a new one."
        case .noRegistrationFound:
            return "Use the `register` or `registerAsync` method to register the dependency."
        case .circularDependencyDetected:
            // swiftlint:disable:next line_length
            return "Break the circular dependency by introducing an abstraction or using a different dependency injection pattern or by using `postInitAction` to initialize cyclical dependencies."
        case .underlyingError:
            return "Check the factory closure for errors and ensure that it's correctly implemented."
        }
    }
}

extension AstrojectError: Equatable where Product: Equatable {
    public static func == (lhs: AstrojectError<Product>, rhs: AstrojectError<Product>) -> Bool {
        switch (lhs, rhs) {
        case (.alreadyRegistered(let lhsType, let lhsName), .alreadyRegistered(let rhsType, let rhsName)):
            return lhsType == rhsType && lhsName == rhsName
        case (.noRegistrationFound, .noRegistrationFound),
             (.circularDependencyDetected, .circularDependencyDetected):
            return true
        case (.underlyingError(let lhsError), .underlyingError(let rhsError)):
            return String(describing: lhsError) == String(describing: rhsError)
        default:
            return false
        }
    }
}