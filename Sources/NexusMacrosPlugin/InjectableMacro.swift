//
//  InjectableMacro.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `@Injectable`: generates an `Injectable` conformance that registers the
/// type by its initializer.
public struct InjectableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let isStruct = declaration.is(StructDeclSyntax.self)
        guard isStruct || declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: InjectableDiagnostic.notClassOrStruct)
            ])
        }
        if declaration.as(StructDeclSyntax.self)?.genericParameterClause != nil
            || declaration.as(ClassDeclSyntax.self)?.genericParameterClause != nil {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: InjectableDiagnostic.generic)
            ])
        }

        let typeName = type.trimmedDescription
        if InjectedProperty.hasAny(in: declaration) {
            return try injectExtension(
                of: node,
                attachedTo: declaration,
                typeName: typeName,
                isStruct: isStruct
            )
        }

        let arguments = try InjectableArguments(node)
        let initializer = try InitializerChoice.choose(
            in: declaration,
            isStruct: isStruct,
            attribute: node
        )

        var location = ""
        if let source = context.location(of: node) {
            location = ", fileID: \(source.file.trimmedDescription), line: \(source.line.trimmedDescription)"
        }
        let nameArgument = arguments.name.map { ", name: \($0)" } ?? ""
        let access = accessModifier(of: declaration)
        let needsConformance = protocols.contains {
            ["Injectable", "AstrojectNexus.Injectable"].contains($0.trimmedDescription)
        }
        let conformance = needsConformance ? ": AstrojectNexus.Injectable" : ""
        let chain = arguments.scopeCall + arguments.forwardedTypes.map { ".implements(\($0).self)" }.joined()
        // A conversion the compiler checks, so a missing conformance is a build error
        // rather than a failed resolve at runtime.
        let conformanceChecks = arguments.forwardedTypes.map {
            "_ = { (instance: \(typeName)) -> \($0) in instance }\n"
        }.joined()
        
        let members: String
        if initializer.hasArguments {
            if !arguments.forwardedTypes.isEmpty {
                throw DiagnosticsError(diagnostics: [
                    Diagnostic(node: node, message: InjectableDiagnostic.asWithArguments)
                ])
            }
            members = factoryMembers(
                typeName: typeName,
                initializer: initializer,
                access: access,
                registration: arguments.environmentGuard + "try container.register(Factory.self\(nameArgument), "
                    + "resolveSync: { resolver in Factory(resolver: resolver) }, "
                    + "resolveAsync: { resolver in Factory(resolver: resolver) }\(location))\(chain)"
            )
        } else if initializer.hasNamed {
            let syncClosure = initializer.isAsync
                ? "nil"
                : "{ resolver in \(initializer.call(typeName: typeName, isAsync: false)) }"
            let asyncClosure = "{ resolver in \(initializer.call(typeName: typeName, isAsync: true)) }"
            let registration = "try container.register(\(typeName).self\(nameArgument), "
                + "resolveSync: \(syncClosure), resolveAsync: \(asyncClosure)\(location))\(chain)"
            members = """
                    \(access)static func register(in container: any AstrojectCore.Container) throws {
                        \(arguments.environmentGuard)\(conformanceChecks)\(registration)
                    }
                """
        } else {
            let reference = initializer.reference(to: typeName)
            let registration = "try container.register(\(typeName).self\(nameArgument), "
                + "initializer: \(reference)\(location))\(chain)"
            members = """
                    \(access)static func register(in container: any AstrojectCore.Container) throws {
                        \(arguments.environmentGuard)\(conformanceChecks)\(registration)
                    }
                """
        }
        
        let decl: DeclSyntax = """
            extension \(raw: typeName)\(raw: conformance) {
            \(raw: members)
            }
            """
        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else { return [] }
        return [extensionDecl]
    }

    /// The extension for a type with `@Inject` properties: an `inject(from:)` that assigns
    /// each one, and no registration, because the system creates the instance.
    static func injectExtension(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        typeName: String,
        isStruct: Bool
    ) throws -> [ExtensionDeclSyntax] {
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self), !arguments.isEmpty {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: InjectDiagnostic.argumentsWithInject)
            ])
        }
        let properties = InjectedProperty.all(in: declaration)
        guard !properties.isEmpty else { return [] }
        let access = accessModifier(of: declaration)
        let mutating = isStruct ? "mutating " : ""
        let assignments = properties.map(\.assignment).joined(separator: "\n")
        let decl: DeclSyntax = """
            extension \(raw: typeName) {
                /// Assigns every `@Inject` property from `resolver`.
                \(raw: access)\(raw: mutating)func inject(from resolver: any AstrojectCore.Resolver) throws {
                    \(raw: assignments)
                }
            }
            """
        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else { return [] }
        return [extensionDecl]
    }

    /// The nested `Factory` and `register(in:)` for a type with `@Argument` parameters.
    ///
    /// `Factory.make(…)` takes the `@Argument` parameters and resolves the rest. It is
    /// registered instead of the type. A synchronous `make` is generated for synchronous
    /// initializers, and an `async` one always, for `AsyncContainer`.
    static func factoryMembers(
        typeName: String,
        initializer: InitializerChoice,
        access: String,
        registration: String
    ) -> String {
        let makeParameters = initializer.parameters.compactMap { parameter -> String? in
            guard case .argument = parameter.kind else { return nil }
            let names = parameter.label == parameter.internalName
                ? parameter.label
                : "\(parameter.label) \(parameter.internalName)"
            return "\(names): \(parameter.type)"
        }.joined(separator: ", ")
        
        var makes: [String] = []
        if !initializer.isAsync {
            makes.append("""
                        \(access)func make(\(makeParameters)) throws -> \(typeName) {
                            \(initializer.call(typeName: typeName, isAsync: false))
                        }
                """)
        }
        makes.append("""
                    \(access)func make(\(makeParameters)) async throws -> \(typeName) {
                        \(initializer.call(typeName: typeName, isAsync: true))
                    }
            """)
        
        return """
                /// Makes `\(typeName)` from its `@Argument` values, resolving everything else.
                \(access)struct Factory {
                    \(access)let resolver: any AstrojectCore.Resolver

                    \(access)init(resolver: any AstrojectCore.Resolver) {
                        self.resolver = resolver
                    }

            \(makes.joined(separator: "\n\n"))
                }

                \(access)static func register(in container: any AstrojectCore.Container) throws {
                    \(registration)
                }
            """
    }
    
    /// `public ` when the type is `public` or `open`, `package ` when it is `package`, otherwise empty.
    static func accessModifier(of declaration: some DeclGroupSyntax) -> String {
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open):
                return "public "
            case .keyword(.package):
                return "package "
            default:
                continue
            }
        }
        return ""
    }
}

/// Implements `@InjectableInit`, a marker that `@Injectable` reads. It adds nothing.
public struct InjectableInitMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(InitializerDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: InjectableDiagnostic.injectableInitNotOnInitializer)
            ])
        }
        return []
    }
}

// MARK: - Arguments

/// The parsed `scope:`, `name:` and `as:` arguments of `@Injectable`.
struct InjectableArguments {
    /// The types listed in `as:`, without `.self`, such as `PuzzleRepositoryProtocol`.
    var forwardedTypes: [String] = []
    /// The scope method to chain, such as `.asSingleton()`, or empty for the default graph scope.
    var scopeCall = ""
    /// The `name:` expression as written, or `nil` when there is none.
    var name: String?
    /// The `environments:` expression as written, such as `[.debug, .test]`, or `nil` when there is none.
    var environments: String?
    
    /// The statement that skips the registration outside `environments`, or empty when there are none.
    var environmentGuard: String {
        environments.map { "guard AstrojectCore.AstrojectEnvironment.includes(\($0)) else {\n    return\n}\n" } ?? ""
    }

    init(_ node: AttributeSyntax) throws {
        guard let list = node.arguments?.as(LabeledExprListSyntax.self) else { return }
        // Variadic `as:` values after the first one have no label of their own
        var currentLabel: String?
        for argument in list {
            if let label = argument.label?.text {
                currentLabel = label
            }
            switch currentLabel {
            case "scope":
                guard let member = argument.expression.as(MemberAccessExprSyntax.self) else {
                    throw DiagnosticsError(diagnostics: [
                        Diagnostic(node: argument.expression, message: InjectableDiagnostic.scopeNotLiteral)
                    ])
                }
                switch member.declName.baseName.text {
                case "graph": scopeCall = ""
                case "singleton": scopeCall = ".asSingleton()"
                case "transient": scopeCall = ".asTransient()"
                case "weak": scopeCall = ".asWeak()"
                default:
                    throw DiagnosticsError(diagnostics: [
                        Diagnostic(node: argument.expression, message: InjectableDiagnostic.scopeNotLiteral)
                    ])
                }
            case "name":
                if !argument.expression.is(NilLiteralExprSyntax.self) {
                    name = argument.expression.trimmedDescription
                }
            case "environments":
                if !argument.expression.is(NilLiteralExprSyntax.self) {
                    environments = argument.expression.trimmedDescription
                }
            case "as":
                guard let member = argument.expression.as(MemberAccessExprSyntax.self),
                      member.declName.baseName.tokenKind == .keyword(.self),
                      let base = member.base else {
                    throw DiagnosticsError(diagnostics: [
                        Diagnostic(node: argument.expression, message: InjectableDiagnostic.asNotType)
                    ])
                }
                forwardedTypes.append(base.trimmedDescription)
            default:
                continue
            }
        }
    }
}

// MARK: - Choosing the initializer

/// The initializer `@Injectable` registers.
struct InitializerChoice {
    /// How one initializer parameter gets its value.
    struct Parameter {
        enum Kind {
            /// Resolved from the container by its type.
            case resolved
            /// Resolved by its type and the name in `@Named("…")`.
            case named(String)
            /// Passed at runtime through the generated `Factory`, marked `@Argument`.
            case argument
        }
        
        /// The argument label, or `_`.
        let label: String
        /// The name used inside the initializer.
        let internalName: String
        /// The parameter's type, as written.
        let type: String
        let kind: Kind
        
        /// The metatype expression for `type`, such as `Logger.self` or `(any Logger).self`.
        var metatype: String {
            type.hasPrefix("any ") || type.hasPrefix("some ") ? "(\(type)).self" : "\(type).self"
        }
        
        init(_ syntax: FunctionParameterSyntax) {
            label = syntax.firstName.text
            internalName = (syntax.secondName ?? syntax.firstName).text
            type = syntax.type.trimmedDescription
            var kind = Kind.resolved
            for element in syntax.attributes {
                guard let attribute = element.as(AttributeSyntax.self) else { continue }
                switch attribute.attributeName.trimmedDescription {
                case "Named", "AstrojectNexus.Named":
                    let name = attribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
                    kind = .named(name?.trimmedDescription ?? "nil")
                case "Argument", "AstrojectNexus.Argument":
                    kind = .argument
                default:
                    continue
                }
            }
            self.kind = kind
        }
    }
    
    /// The argument labels, with `_` for unlabeled parameters.
    let labels: [String]
    let isAsync: Bool
    let isThrowing: Bool
    /// The chosen initializer's parameters. Empty for an implicit initializer.
    var parameters: [Parameter] = []
    
    /// Whether any parameter is marked `@Argument`, so a `Factory` is generated.
    var hasArguments: Bool {
        parameters.contains { if case .argument = $0.kind { true } else { false } }
    }
    
    /// Whether any parameter is marked `@Named`, so the initializer is called from a resolving closure.
    var hasNamed: Bool {
        parameters.contains { if case .named = $0.kind { true } else { false } }
    }
    
    /// A call to the initializer, such as `try await Type(logger: resolver.resolve(Logger.self))`.
    /// `@Argument` parameters are passed by their internal names.
    func call(typeName: String, isAsync: Bool) -> String {
        let arguments = parameters.map { parameter -> String in
            let value: String
            switch parameter.kind {
            case .resolved:
                value = "resolver.resolve(\(parameter.metatype))"
            case .named(let name):
                value = "resolver.resolve(\(parameter.metatype), name: \(name))"
            case .argument:
                value = parameter.internalName
            }
            return parameter.label == "_" ? value : "\(parameter.label): \(value)"
        }
        return "try \(isAsync ? "await " : "")\(typeName)(\(arguments.joined(separator: ", ")))"
    }

    /// The expression passed as `initializer:`.
    ///
    /// An initializer with parameters is referenced by its full name, such as
    /// `Type.init(api:logger:)`. One without parameters is wrapped in a closure,
    /// because `Type.init()` would call it.
    func reference(to typeName: String) -> String {
        guard labels.isEmpty else {
            return "\(typeName).init(\(labels.map { "\($0):" }.joined()))"
        }
        let effects = (isThrowing ? "try " : "") + (isAsync ? "await " : "")
        return "{ \(effects)\(typeName)() }"
    }

    /// Picks the initializer: the one marked `@InjectableInit`, the only one declared, or
    /// the implicit one when none is declared (memberwise for a struct).
    static func choose(
        in declaration: some DeclGroupSyntax,
        isStruct: Bool,
        attribute: AttributeSyntax
    ) throws -> InitializerChoice {
        let initializers = declaration.memberBlock.members.compactMap {
            $0.decl.as(InitializerDeclSyntax.self)
        }
        let marked = initializers.filter(isMarked)

        let chosen: InitializerDeclSyntax
        if marked.count > 1 {
            throw DiagnosticsError(diagnostics: marked.dropFirst().map {
                Diagnostic(node: $0, message: InjectableDiagnostic.multipleMarked)
            })
        } else if let only = marked.first {
            chosen = only
        } else if initializers.count == 1, let only = initializers.first {
            chosen = only
        } else if initializers.isEmpty {
            let labels = isStruct ? memberwiseLabels(of: declaration) : []
            return InitializerChoice(labels: labels, isAsync: false, isThrowing: false)
        } else {
            let fixIts = initializers.map { initializer in
                FixIt(
                    message: InjectableFixIt(
                        "Mark '\(signatureName(of: initializer))' with @InjectableInit"
                    ),
                    changes: [.replace(oldNode: Syntax(initializer), newNode: Syntax(markedCopy(of: initializer)))]
                )
            }
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: attribute, message: InjectableDiagnostic.multipleInitializers, fixIts: fixIts)
            ])
        }

        if chosen.optionalMark != nil {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: chosen, message: InjectableDiagnostic.failable)
            ])
        }

        let effects = chosen.signature.effectSpecifiers
        return InitializerChoice(
            labels: chosen.signature.parameterClause.parameters.map(\.firstName.text),
            isAsync: effects?.asyncSpecifier != nil,
            isThrowing: effects?.throwsClause != nil,
            parameters: chosen.signature.parameterClause.parameters.map(Parameter.init)
        )
    }

    /// Whether `initializer` carries `@InjectableInit`.
    static func isMarked(_ initializer: InitializerDeclSyntax) -> Bool {
        initializer.attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else { return false }
            let name = attribute.attributeName.trimmedDescription
            return name == "InjectableInit" || name == "AstrojectNexusMacros.InjectableInit"
        }
    }

    /// The labels of a struct's memberwise initializer: every stored instance property,
    /// except a `let` that already has a value.
    static func memberwiseLabels(of declaration: some DeclGroupSyntax) -> [String] {
        var labels: [String] = []
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            let isStatic = variable.modifiers.contains {
                $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
            }
            guard !isStatic else { continue }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            for binding in variable.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                if isLet, binding.initializer != nil { continue }
                if let accessors = binding.accessorBlock, !isObserversOnly(accessors) { continue }
                labels.append(pattern.identifier.text)
            }
        }
        return labels
    }

    /// Whether an accessor block only has `willSet`/`didSet`, so the property is still stored.
    static func isObserversOnly(_ block: AccessorBlockSyntax) -> Bool {
        guard case .accessors(let accessors) = block.accessors else { return false }
        return accessors.allSatisfy {
            $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
        }
    }

    /// A name like `init(api:logger:)`.
    static func signatureName(of initializer: InitializerDeclSyntax) -> String {
        let labels = initializer.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        return "init(\(labels.joined()))"
    }

    /// `initializer` with `@InjectableInit` on the line above it.
    static func markedCopy(of initializer: InitializerDeclSyntax) -> DeclSyntax {
        let leading = initializer.leadingTrivia.description
        let indentation = leading.split(separator: "\n", omittingEmptySubsequences: false).last ?? ""
        let text = "\(leading)@InjectableInit\n\(indentation)\(initializer.trimmedDescription)"
            + initializer.trailingTrivia.description
        return DeclSyntax(stringLiteral: text)
    }
}

// MARK: - Diagnostics

enum InjectableDiagnostic: String, DiagnosticMessage {
    case notClassOrStruct
    case generic
    case multipleInitializers
    case multipleMarked
    case failable
    case scopeNotLiteral
    case injectableInitNotOnInitializer
    case asNotType
    case asWithArguments

    var message: String {
        switch self {
        case .notClassOrStruct:
            "@Injectable can only be applied to a class or struct"
        case .generic:
            "@Injectable doesn't support generic types; register them with register(_:initializer:)"
        case .multipleInitializers:
            "@Injectable needs to know which initializer to use; mark one with @InjectableInit"
        case .multipleMarked:
            "Only one initializer can be marked @InjectableInit"
        case .failable:
            "@Injectable can't use a failable initializer"
        case .scopeNotLiteral:
            "scope must be one of .graph, .singleton, .transient or .weak"
        case .injectableInitNotOnInitializer:
            "@InjectableInit can only be applied to an initializer"
        case .asNotType:
            "as: takes types, such as PuzzleRepositoryProtocol.self"
        case .asWithArguments:
            "as: can't be used with @Argument parameters; the type is made through its Factory instead"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "AstrojectNexusMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}

struct InjectableFixIt: FixItMessage {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var fixItID: MessageID {
        MessageID(domain: "AstrojectNexusMacros", id: "markInjectableInit")
    }
}
