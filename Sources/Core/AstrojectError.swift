import Foundation

/// Represents errors that can occur during dependency registration and resolution
/// within the Astroject dependency injection framework.
///
/// This enum consolidates various error scenarios, including issues related to
/// dependency registration, resolution, and factory execution.
/// It conforms to `LocalizedError` to provide user-friendly error descriptions,
/// failure reasons, and recovery suggestions.
public enum AstrojectError: LocalizedError {
    /// Indicates that a registration for the given key already exists.
    ///
    /// This error occurs when you try to register a dependency with a `RegistrationKey`
    /// that has already been used, and the existing registration is not overridable,
    /// or the new registration is not marked as overridable.
    ///
    /// - Parameter key: The `RegistrationKey` that is already registered.
    case alreadyRegistered(key: RegistrationKey)
    
    /// Indicates that no registration could be found for the given key.
    ///
    /// This error occurs when you try to resolve a dependency using a `RegistrationKey`
    /// for which no corresponding registration has been made in the container.
    ///
    /// - Parameter key: The `RegistrationKey` for which no registration was found.
    case noRegistrationFound(key: RegistrationKey)
    
    /// Indicates that a circular dependency was detected during resolution.
    ///
    /// This error occurs when the dependency graph forms a cycle, meaning
    /// a dependency indirectly or directly relies on itself for its creation,
    /// leading to an infinite loop during resolution.
    ///
    /// - Parameters:
    ///   - key: The `RegistrationKey` of the dependency that caused the cycle.
    ///   - path: The resolution path that led to the cyclic dependency, showing the sequence of `RegistrationKey`s.
    case cyclicDependency(key: RegistrationKey, path: [RegistrationKey])
    
    /// An error occurred within the factory closure during dependency resolution.
    ///
    /// This case wraps an underlying error that occurred while executing the factory
    /// closure responsible for creating a dependency instance.
    case underlyingError(Error)
    
    /// A synchronous resolution method was called for a dependency that was registered with an asynchronous factory.
    ///
    /// This case indicates that you attempted to resolve a dependency synchronously
    /// (e.g., using `resolve()`) when its registration factory (`registerAsync`)
    /// requires asynchronous execution.
    case invalidFactory
    
    /// An error occurred during a registration-related action.
    ///
    /// This case wraps an underlying error that happened within a closure or operation
    /// associated with the registration of a dependency, such as a `postInitAction`.
    ///
    /// - Parameter error: The underlying `Error` that occurred during the registration action.
    case registrationAction(Error)
    
    /// Provides a user-friendly description of the error.
    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered(let key):
            return "A registration for key '\(key)' already exists."
        case .noRegistrationFound(let key):
            return "No registration found for dependency for key '\(key)'."
        case .cyclicDependency(let key, let path):
            let pathString = path.map { "\($0.productType)" }.joined(separator: " -> ")
            return "Cyclic Dependency Detected for \(key). Resolution path: \(pathString)"
        case .underlyingError(let error):
            return "An error occurred within the factory closure: \(error.localizedDescription)"
        case .invalidFactory:
            // swiftlint:disable:next line_length
            return "Attempted to resolve an asynchronously/synchronously registered dependency using a synchronous/asynchronous method."
        case .registrationAction(let error):
            return "An error occurred during a registration action: \(error.localizedDescription)"
        }
    }
    
    /// Provides a reason for the error, explaining why it occurred.
    public var failureReason: String? {
        switch self {
        case .alreadyRegistered:
            return "Attempting to register a dependency with a ProductKey that has already been used."
        case .noRegistrationFound:
            return "Register the dependency before attempting to resolve it."
        case .cyclicDependency:
            return "Review your dependency graph to eliminate circular dependencies."
        case .underlyingError:
            return "Inspect the underlying error for more details."
        case .invalidFactory:
            // swiftlint:disable:next line_length
            return "The dependency was registered with an asynchronous factory (e.g., using `registerAsync`), but a synchronous resolution method (e.g., `resolve()`) was called."
        case .registrationAction:
            // swiftlint:disable:next line_length
            return "A problem occurred within a closure or operation executed during dependency registration (e.g., a post-initialization action)."
        }
    }
    
    /// Provides a suggestion for recovering from the error.
    public var recoverySuggestion: String? {
        switch self {
        case .alreadyRegistered:
            return "Use a different ProductKey or remove the existing registration before registering a new one."
        case .noRegistrationFound:
            return "Use the `register` or `registerAsync` method to register the dependency."
        case .cyclicDependency:
            // swiftlint:disable:next line_length
            return "Break the circular dependency by introducing an abstraction or using a different dependency injection pattern or by using `postInitAction` to initialize cyclical dependencies."
        case .underlyingError:
            return "Check the factory closure for errors and ensure that it's correctly implemented."
        case .invalidFactory:
            // swiftlint:disable:next line_length
            return "Use an asynchronous resolution method (e.g., `resolveAsync()`) to resolve the dependency, or register it with a synchronous factory if synchronous resolution is intended."
        case .registrationAction:
            // swiftlint:disable:next line_length
            return "Review the code within the registration action (e.g., your `postInitAction` closure) for potential errors."
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
        case (.alreadyRegistered(let lhsKey), .alreadyRegistered(let rhsKey)),
            (.noRegistrationFound(let lhsKey),
             .noRegistrationFound(let rhsKey)):
            // Compare the associated keys for alreadyRegistered and noRegistrationFound errors.
            return lhsKey == rhsKey
        case (.cyclicDependency(let lhsKey, let lhsPath),
              .cyclicDependency(let rhsKey, let rhsPath)):
            // Compare the associated keys and paths for cyclicDependency errors.
            return lhsKey == rhsKey && lhsPath == rhsPath
        case (.invalidFactory, .invalidFactory):
            // invalidInstance and invalidFactory
            // errors are equal if they are the same case.
            return true
        case (.underlyingError(let lhsError), .underlyingError(let rhsError)),
            (.registrationAction(let lhsError), .registrationAction(let rhsError)):
            // Compare the descriptions of the underlying errors for both cases.
            return String(describing: lhsError) == String(describing: rhsError)
        default:
            // All other cases are not equal.
            return false
        }
    }
}
