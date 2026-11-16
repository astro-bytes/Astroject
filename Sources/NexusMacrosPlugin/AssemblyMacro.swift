//
//  AssemblyMacro.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements `@Assembly`: generates an `Assembly` conformance that registers the listed
/// `Injectable` types in order.
public struct AssemblyMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: AssemblyDiagnostic.notClassOrStruct)
            ])
        }
        
        let arguments = try AssemblyArguments(node)
        warnAboutDuplicates(in: arguments.types, context: context)
        
        let access = InjectableMacro.accessModifier(of: declaration)
        let conformance = protocols.isEmpty ? "" : ": AstrojectCore.Assembly"
        
        var members: [String] = []
        if !arguments.requires.isEmpty {
            let list = arguments.requires.map(\.text).joined(separator: ", ")
            members.append("""
                    \(access)static var requiredAssemblies: [any AstrojectCore.Assembly.Type] {
                        [\(list)]
                    }
                """)
        }
        let body = arguments.types
            .map { "        try \($0.text).register(in: container)\n" }
            .joined()
        members.append("""
                \(access)func assemble(container: any AstrojectCore.Container) throws {
            \(body)    }
            """)
        
        let decl: DeclSyntax = """
            extension \(raw: type.trimmedDescription)\(raw: conformance) {
            \(raw: members.joined(separator: "\n\n"))
            }
            """
        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else { return [] }
        return [extensionDecl]
    }
    
    /// Warns when a type is listed more than once: registration is last one wins, so the
    /// earlier registration is replaced.
    static func warnAboutDuplicates(in types: [AssemblyArguments.TypeEntry], context: some MacroExpansionContext) {
        var seen: Set<String> = []
        for entry in types where !seen.insert(entry.text).inserted {
            context.diagnose(Diagnostic(
                node: entry.node,
                message: AssemblyDiagnostic.duplicateType(entry.text)
            ))
        }
    }
}

// MARK: - Arguments

/// The parsed arguments of `@Assembly`.
struct AssemblyArguments {
    /// A type listed in the attribute, written without `.self`.
    struct TypeEntry {
        let text: String
        let node: ExprSyntax
    }
    
    /// The `Injectable` types to register, in order.
    var types: [TypeEntry] = []
    /// The assemblies listed in `requires:`, written with `.self`.
    var requires: [TypeEntry] = []
    
    init(_ node: AttributeSyntax) throws {
        guard let list = node.arguments?.as(LabeledExprListSyntax.self) else { return }
        for argument in list {
            switch argument.label?.text {
            case nil:
                types.append(TypeEntry(text: try Self.typeName(argument.expression), node: argument.expression))
            case "requires":
                guard let array = argument.expression.as(ArrayExprSyntax.self) else {
                    throw DiagnosticsError(diagnostics: [
                        Diagnostic(node: argument.expression, message: AssemblyDiagnostic.requiresNotArray)
                    ])
                }
                for element in array.elements {
                    let name = try Self.typeName(element.expression)
                    requires.append(TypeEntry(text: "\(name).self", node: element.expression))
                }
            default:
                continue
            }
        }
    }
    
    /// The type in an expression like `UserService.self`, as written.
    static func typeName(_ expression: ExprSyntax) throws -> String {
        guard let member = expression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.tokenKind == .keyword(.self),
              let base = member.base else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: expression, message: AssemblyDiagnostic.notType)
            ])
        }
        return base.trimmedDescription
    }
}

// MARK: - Diagnostics

enum AssemblyDiagnostic: DiagnosticMessage {
    case notClassOrStruct
    case notType
    case requiresNotArray
    case duplicateType(String)
    
    var message: String {
        switch self {
        case .notClassOrStruct:
            "@Assembly can only be applied to a class or struct"
        case .notType:
            "@Assembly takes types, such as UserService.self"
        case .requiresNotArray:
            "requires: takes an array of assemblies, such as [DataAssembly.self]"
        case .duplicateType(let name):
            "\(name) is listed more than once; registration is last one wins, so only the last one takes effect"
        }
    }
    
    var diagnosticID: MessageID {
        switch self {
        case .notClassOrStruct: MessageID(domain: "AstrojectNexusMacros", id: "assemblyNotClassOrStruct")
        case .notType: MessageID(domain: "AstrojectNexusMacros", id: "assemblyNotType")
        case .requiresNotArray: MessageID(domain: "AstrojectNexusMacros", id: "assemblyRequiresNotArray")
        case .duplicateType: MessageID(domain: "AstrojectNexusMacros", id: "assemblyDuplicateType")
        }
    }
    
    var severity: DiagnosticSeverity {
        switch self {
        case .duplicateType: .warning
        default: .error
        }
    }
}
