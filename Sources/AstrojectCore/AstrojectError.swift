//
// AstrojectError.swift
// Astroject
//
// Created by Porter McGary on 2/27/25.
//

import Foundation

/// Represents errors that can occur during dependency registration and resolution
/// within the Astroject dependency injection framework.
///
/// This enum consolidates various error scenarios, including issues related to
/// dependency registration, resolution, and factory execution.
/// It conforms to `LocalizedError` to provide user-friendly error descriptions,
/// failure reasons, and recovery suggestions.
public enum AstrojectError: LocalizedError {
    /// A registration is attempted with a `RegistrationKey` that already exists.
    ///
    /// This case indicates that a dependency registration with the same type and
    /// optional name has already been performed.
    case alreadyRegistered(type: String, name: String? = nil)

    /// A dependency is requested but no corresponding registration is found in the container.
    ///
    /// This case occurs when attempting to resolve a dependency that has not been registered.
    case noRegistrationFound

    /// A circular dependency is detected during the resolution process.
    ///
    /// This case indicates that a chain of dependencies forms a loop, preventing successful resolution.
    case circularDependencyDetected

    /// An error occurred within the factory closure during dependency resolution.
    ///
    /// This case wraps an underlying error that occurred while executing the factory
    /// closure responsible for creating a dependency instance.
    case underlyingError(Error)

    /// Provides a user-friendly description of the error.
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

    /// Provides a reason for the error, explaining why it occurred.
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

    /// Provides a suggestion for recovering from the error.
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

/// Extends `AstrojectError` to conform to `Equatable` when the associated `Product` type is also `Equatable`.
///
/// This extension allows for easy comparison of `AstrojectError` instances based on their associated values.
extension AstrojectError: Equatable {
    /// Checks if two `AstrojectError` instances are equal.
    ///
    /// - parameter lhs: The left-hand side `AstrojectError` instance.
    /// - parameter rhs: The right-hand side `AstrojectError` instance.
    /// - Returns: `true` if the errors are equal, `false` otherwise.
    public static func == (lhs: AstrojectError, rhs: AstrojectError) -> Bool {
        switch (lhs, rhs) {
        case (.alreadyRegistered(let lhsType, let lhsName), .alreadyRegistered(let rhsType, let rhsName)):
            // Compare the associated types and names for alreadyRegistered errors.
            return lhsType == rhsType && lhsName == rhsName
        case (.noRegistrationFound, .noRegistrationFound),
             (.circularDependencyDetected, .circularDependencyDetected):
            // noRegistrationFound and circularDependencyDetected errors are equal if they are the same case.
            return true
        case (.underlyingError(let lhsError), .underlyingError(let rhsError)):
            // Compare the descriptions of the underlying errors.
            return String(describing: lhsError) == String(describing: rhsError)
        default:
            // All other cases are not equal.
            return false
        }
    }
}
