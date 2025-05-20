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
    case noRegistrationFound(type: String, name: String? = nil)
    
    /// A circular dependency is detected during the resolution process.
    ///
    /// This case indicates that a chain of dependencies forms a loop, preventing successful resolution.
    case circularDependencyDetected(type: String, name: String? = nil)
    
    /// An error occurred within the factory closure during dependency resolution.
    ///
    /// This case wraps an underlying error that occurred while executing the factory
    /// closure responsible for creating a dependency instance.
    case underlyingError(Error)
    
    /// An invalid instance was encountered during resolution.
    ///
    /// This error occurs when the instance being resolved is not valid or
    /// does not conform to the expected type.  This can happen if the
    /// Instance implementation is incorrect, or if there is a mismatch
    /// between the registered type and the actual type of the resolved instance.
    case invalidInstance
    
    /// Provides a user-friendly description of the error.
    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered(let type, let name):
            if let name = name {
                return "A registration for type '\(type)' with name '\(name)' already exists."
            } else {
                return "A registration for type '\(type)' already exists."
            }
        case .noRegistrationFound(let type, let name):
            if let name {
                return "No registration found for dependency of '\(type)' with name '\(name)'."
            } else {
                return "No registration found for dependency of '\(type)'."
            }
        case .circularDependencyDetected(let type, let name):
            if let name = name {
                return "A circular dependency was detected while resolving type '\(type)' with name '\(name)'."
            } else {
                return "A circular dependency was detected."
            }
        case .underlyingError(let error):
            return "An error occurred within the factory closure: \(error.localizedDescription)"
        case .invalidInstance:
            return "The resolved instance is invalid or of an unexpected type."
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
        case .invalidInstance:
            return "The resolved instance did not match the expected type or was invalid."
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
        case .invalidInstance:
            // swiftlint:disable:next line_length
            return "Ensure that the Instance implementation is correct and that the registered type matches the actual type of the resolved instance."
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
        case (.alreadyRegistered(let lhsType, let lhsName), .alreadyRegistered(let rhsType, let rhsName)),
            (.noRegistrationFound(let lhsType, let lhsName),
             .noRegistrationFound(let rhsType, let rhsName)),
            (.circularDependencyDetected(let lhsType, let lhsName),
             .circularDependencyDetected(let rhsType, let rhsName)):
            // Compare the associated types and names for alreadyRegistered and circularDependencyDetected errors.
            return lhsType == rhsType && lhsName == rhsName
        case (.invalidInstance, .invalidInstance):
            // noRegistrationFound and invalidInstance errors are equal if they are the same case.
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
