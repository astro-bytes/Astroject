//
//  NexusMacros.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

// The Nexus macros. Importing this module also imports the Nexus runtime,
// which the generated code calls.
@_exported import AstrojectNexus
@_exported import AstrojectCore

/// Registers a class or struct by its initializer.
///
/// The macro generates an `Injectable` conformance whose `register(in:)` registers the type
/// with Nexus's `register(_:name:initializer:)`, so every initializer parameter is resolved
/// from the container by its type.
///
/// ```swift
/// @Injectable(scope: .singleton, name: "primary")
/// final class PuzzleRepository {
///     init(api: APIClient, logger: Logger) { ... }
/// }
///
/// // Generated:
/// extension PuzzleRepository: Injectable {
///     static func register(in container: any Container) throws {
///         try container.register(
///             PuzzleRepository.self,
///             name: "primary",
///             initializer: PuzzleRepository.init(api:logger:),
///             fileID: "App/PuzzleRepository.swift",
///             line: 1
///         )
///         .asSingleton()
///     }
/// }
/// ```
///
/// When the type has more than one initializer, mark the one to use with `@InjectableInit`.
/// A struct with no initializer uses its memberwise initializer. `async` and `throws`
/// initializers work; an `async` one needs an `AsyncContainer`.
///
/// List protocols (or superclasses) in `as:` to also resolve the type by them. Each one is
/// forwarded to the same registration, so a singleton is shared. The macro also makes the
/// compiler check that the type conforms, so a missing conformance is a build error:
///
/// ```swift
/// @Injectable(scope: .singleton, as: PuzzleRepositoryProtocol.self)
/// final class RemotePuzzleRepository: PuzzleRepositoryProtocol { ... }
/// ```
///
/// - Parameters:
///   - scope: How instances are managed. Defaults to `.graph`.
///   - name: An optional name for the registration. Forwarded types use the same name.
///   - types: Protocols or superclasses to also register the type as.
@attached(extension, conformances: Injectable, names: named(register(in:)))
public macro Injectable(
    scope: InjectableScope = .graph,
    name: String? = nil,
    as types: Any.Type...
) = #externalMacro(module: "AstrojectNexusMacrosPlugin", type: "InjectableMacro")

/// Marks the initializer `@Injectable` registers, when the type has more than one.
@attached(peer)
public macro InjectableInit() = #externalMacro(module: "AstrojectNexusMacrosPlugin", type: "InjectableInitMacro")
