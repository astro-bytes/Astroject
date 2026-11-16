//
//  InjectMacro.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `@Inject`, a marker that `@Injectable` reads. It checks the property and adds nothing.
public struct InjectMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        _ = try InjectedProperty(declaration: declaration, attribute: node)
        return []
    }
}

/// A stored property marked `@Inject`, which `inject(from:)` assigns.
struct InjectedProperty {
    /// The property's name.
    let name: String
    /// The resolved type, without the `?` or `!`, such as `AnalyticsService`.
    let type: String
    /// The `name:` expression as written, or `nil` when there is none.
    let registrationName: String?

    /// The metatype expression for `type`, such as `Logger.self` or `(any Logger).self`.
    var metatype: String {
        type.hasPrefix("any ") || type.hasPrefix("some ") ? "(\(type)).self" : "\(type).self"
    }

    /// The assignment `inject(from:)` makes, such as `self.logger = try resolver.resolve(Logger.self)`.
    var assignment: String {
        let nameArgument = registrationName.map { ", name: \($0)" } ?? ""
        return "self.\(name) = try resolver.resolve(\(metatype)\(nameArgument))"
    }

    /// Reads and checks a property marked `@Inject`.
    ///
    /// - Throws: A diagnostic when the property isn't a single stored instance `var` with an
    ///   optional or implicitly unwrapped type.
    init(declaration: some DeclSyntaxProtocol, attribute: AttributeSyntax) throws {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw Self.error(attribute, .notProperty)
        }
        guard variable.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw Self.error(variable.bindingSpecifier, .notVar)
        }
        let isStatic = variable.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
        guard !isStatic else {
            throw Self.error(attribute, .isStatic)
        }
        guard variable.bindings.count == 1,
              let binding = variable.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw Self.error(attribute, .multipleBindings)
        }
        if let accessors = binding.accessorBlock, !InitializerChoice.isObserversOnly(accessors) {
            throw Self.error(attribute, .computed)
        }
        guard let annotation = binding.typeAnnotation?.type else {
            throw Self.error(pattern, .notOptional)
        }
        if let optional = annotation.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            type = Self.unwrapped(optional.wrappedType)
        } else if let optional = annotation.as(OptionalTypeSyntax.self) {
            type = Self.unwrapped(optional.wrappedType)
        } else {
            throw Self.error(annotation, .notOptional)
        }
        name = pattern.identifier.text
        registrationName = attribute.arguments?.as(LabeledExprListSyntax.self)?
            .first { $0.label?.text == "name" }
            .flatMap { $0.expression.is(NilLiteralExprSyntax.self) ? nil : $0.expression.trimmedDescription }
    }

    /// The wrapped type as written, without the parentheses around `(any P)`.
    static func unwrapped(_ type: TypeSyntax) -> String {
        if let tuple = type.as(TupleTypeSyntax.self),
           tuple.elements.count == 1,
           let only = tuple.elements.first,
           only.firstName == nil {
            return only.type.trimmedDescription
        }
        return type.trimmedDescription
    }

    /// Every property marked `@Inject` in `declaration`, skipping ones `@Inject` itself reports.
    static func all(in declaration: some DeclGroupSyntax) -> [InjectedProperty] {
        declaration.memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  let attribute = injectAttribute(of: variable) else { return nil }
            return try? InjectedProperty(declaration: variable, attribute: attribute)
        }
    }

    /// Whether `declaration` has any property marked `@Inject`, valid or not.
    static func hasAny(in declaration: some DeclGroupSyntax) -> Bool {
        declaration.memberBlock.members.contains { member in
            member.decl.as(VariableDeclSyntax.self).flatMap(injectAttribute) != nil
        }
    }

    static func injectAttribute(of variable: VariableDeclSyntax) -> AttributeSyntax? {
        for element in variable.attributes {
            guard let attribute = element.as(AttributeSyntax.self) else { continue }
            let name = attribute.attributeName.trimmedDescription
            if name == "Inject" || name == "AstrojectNexusMacros.Inject" {
                return attribute
            }
        }
        return nil
    }

    static func error(_ node: some SyntaxProtocol, _ message: InjectDiagnostic) -> DiagnosticsError {
        DiagnosticsError(diagnostics: [Diagnostic(node: node, message: message)])
    }
}

enum InjectDiagnostic: String, DiagnosticMessage {
    case notProperty
    case notVar
    case isStatic
    case multipleBindings
    case computed
    case notOptional
    case argumentsWithInject

    var message: String {
        switch self {
        case .notProperty:
            "@Inject can only be applied to a stored property"
        case .notVar:
            "@Inject requires a 'var', because inject(from:) assigns it after initialization"
        case .isStatic:
            "@Inject can't be applied to a static property"
        case .multipleBindings:
            "@Inject can only be applied to a property that declares one name"
        case .computed:
            "@Inject can't be applied to a computed property"
        case .notOptional:
            "@Inject requires an optional or implicitly unwrapped type, such as 'AnalyticsService!'"
        case .argumentsWithInject:
            "scope:, name: and as: don't apply to a type with @Inject properties, because it isn't registered"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "AstrojectNexusMacros", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}
