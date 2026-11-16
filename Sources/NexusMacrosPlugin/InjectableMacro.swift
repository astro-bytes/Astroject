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

        let arguments = try InjectableArguments(node)
        let typeName = type.trimmedDescription
        let initializer = try InitializerChoice.choose(
            in: declaration,
            isStruct: isStruct,
            attribute: node
        )

        var callArguments = ["\(typeName).self"]
        if let name = arguments.name {
            callArguments.append("name: \(name)")
        }
        callArguments.append("initializer: \(initializer.reference(to: typeName))")
        if let location = context.location(of: node) {
            callArguments.append("fileID: \(location.file.trimmedDescription)")
            callArguments.append("line: \(location.line.trimmedDescription)")
        }

        let access = accessModifier(of: declaration)
        let conformance = protocols.isEmpty ? "" : ": AstrojectNexus.Injectable"
        let scope = arguments.scopeCall
        let decl: DeclSyntax = """
            extension \(raw: typeName)\(raw: conformance) {
                \(raw: access)static func register(in container: any AstrojectCore.Container) throws {
                    try container.register(\(raw: callArguments.joined(separator: ", ")))\(raw: scope)
                }
            }
            """
        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else { return [] }
        return [extensionDecl]
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

/// The parsed `scope:` and `name:` arguments of `@Injectable`.
struct InjectableArguments {
    /// The scope method to chain, such as `.asSingleton()`, or empty for the default graph scope.
    var scopeCall = ""
    /// The `name:` expression as written, or `nil` when there is none.
    var name: String?

    init(_ node: AttributeSyntax) throws {
        guard let list = node.arguments?.as(LabeledExprListSyntax.self) else { return }
        for argument in list {
            switch argument.label?.text {
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
            default:
                continue
            }
        }
    }
}

// MARK: - Choosing the initializer

/// The initializer `@Injectable` registers.
struct InitializerChoice {
    /// The argument labels, with `_` for unlabeled parameters.
    let labels: [String]
    let isAsync: Bool
    let isThrowing: Bool

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
            isThrowing: effects?.throwsClause != nil
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
