/// Errors thrown by `UnifiedContainer`.
///
/// Every error depends only on what is registered, never on timing:
/// a resolve that fails once fails every time.
public enum ContainerError: Error, Equatable, Sendable, CustomStringConvertible {
    /// Nothing is registered for this type and name.
    case noRegistration(String)
    /// The resolution path came back to a type it was already resolving.
    case cyclicDependency([String])
    /// The sync initializer was used, but these assemblies adopt `AsyncSetup`.
    case asyncSetupRequired([String])
    /// The type was registered with `registerMainActor` and resolved off the main actor.
    case mainActorRequired(String)
    /// The type was registered with `registerProvider`; resolve `AsyncProvider<Type>` instead.
    case registeredAsProvider(String)
    /// The stored factory produced a value of the wrong type (should never happen).
    case typeMismatch(expected: String, actual: String)

    public var description: String {
        switch self {
        case .noRegistration(let key):
            "No registration for \(key)."
        case .cyclicDependency(let path):
            "Cyclic dependency: \(path.joined(separator: " -> "))."
        case .asyncSetupRequired(let names):
            "Assemblies \(names.joined(separator: ", ")) need async setup. "
            + "Use `try await UnifiedContainer(assemblies:)`."
        case .mainActorRequired(let key):
            "\(key) is registered on the main actor. Resolve it with `container.main.resolve(_:)`."
        case .registeredAsProvider(let key):
            "\(key) is created asynchronously. Resolve `AsyncProvider<\(key)>` and await it."
        case let .typeMismatch(expected, actual):
            "Expected \(expected), got \(actual)."
        }
    }
}
