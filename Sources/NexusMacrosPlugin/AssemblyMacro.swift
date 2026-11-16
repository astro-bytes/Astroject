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
        let providers = try Provider.all(in: declaration, context: context)
        warnAboutDuplicates(in: arguments.types, providers: providers, context: context)
        
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
        // Listed types first, in order, then @Provides functions top to bottom
        let body = arguments.types
            .map { "        try \($0.text).register(in: container)\n" }
            .joined()
            + providers.flatMap(\.statements).map { "        \($0)\n" }.joined()
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
    
    /// Warns when a type is listed more than once, or two `@Provides` functions provide the
    /// same type and name: registration is last one wins, so the earlier one is replaced.
    ///
    /// The macro can only see this declaration, so it can't compare against `as:` bindings
    /// on the listed types themselves; the registration report shows those after assembly.
    static func warnAboutDuplicates(
        in types: [AssemblyArguments.TypeEntry],
        providers: [Provider],
        context: some MacroExpansionContext
    ) {
        var seen: Set<String> = []
        for entry in types where !seen.insert(entry.text).inserted {
            context.diagnose(Diagnostic(
                node: entry.node,
                message: AssemblyDiagnostic.duplicateType(entry.text)
            ))
        }
        var provided: Set<String> = []
        for provider in providers {
            for key in provider.keys where !provided.insert(key).inserted {
                context.diagnose(Diagnostic(
                    node: provider.attribute,
                    message: AssemblyDiagnostic.duplicateProvider(key)
                ))
            }
        }
    }
}

// MARK: - @Provides

/// A `static` function marked `@Provides`, registered by `@Assembly`.
struct Provider {
    /// The `@Provides` attribute.
    let attribute: AttributeSyntax
    /// The statements that register the function: a compiler-checked conversion for each
    /// `as:` type, then `try container.register(...)`.
    let statements: [String]
    /// The keys this provider registers, such as `Logger` or `Logger "analytics"`, for duplicate warnings.
    let keys: [String]
    
    /// Every `@Provides` function in `declaration`, top to bottom.
    static func all(in declaration: some DeclGroupSyntax, context: some MacroExpansionContext) throws -> [Provider] {
        try declaration.memberBlock.members.compactMap { member -> Provider? in
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  let attribute = providesAttribute(of: function) else { return nil }
            return try Provider(function: function, attribute: attribute, context: context)
        }
    }
    
    static func providesAttribute(of function: FunctionDeclSyntax) -> AttributeSyntax? {
        for element in function.attributes {
            guard let attribute = element.as(AttributeSyntax.self) else { continue }
            let name = attribute.attributeName.trimmedDescription
            if name == "Provides" || name == "AstrojectNexusMacros.Provides" {
                return attribute
            }
        }
        return nil
    }
    
    init(function: FunctionDeclSyntax, attribute: AttributeSyntax, context: some MacroExpansionContext) throws {
        let isStatic = function.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
        guard isStatic else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: function.name, message: AssemblyDiagnostic.providesNotStatic)
            ])
        }
        guard let returnType = function.signature.returnClause?.type,
              !returnType.is(SomeOrAnyTypeSyntax.self) || returnType.trimmedDescription.hasPrefix("any ") else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: function.name, message: AssemblyDiagnostic.providesNeedsReturnType)
            ])
        }
        
        let arguments = try InjectableArguments(attribute)
        let product = returnType.trimmedDescription
        let labels = function.signature.parameterClause.parameters.map { "\($0.firstName.text):" }
        let reference = labels.isEmpty
            ? "Self.\(function.name.text)"
            : "Self.\(function.name.text)(\(labels.joined()))"
        
        // `(any P).self` needs the parentheses; a plain type doesn't
        let metatype = product.hasPrefix("any ") ? "(\(product)).self" : "\(product).self"
        var callArguments = [metatype]
        if let name = arguments.name {
            callArguments.append("name: \(name)")
        }
        callArguments.append("initializer: \(reference)")
        if let location = context.location(of: attribute) {
            callArguments.append("fileID: \(location.file.trimmedDescription)")
            callArguments.append("line: \(location.line.trimmedDescription)")
        }
        let chain = arguments.scopeCall + arguments.forwardedTypes.map { ".implements(\($0).self)" }.joined()
        
        self.attribute = attribute
        let checks = arguments.forwardedTypes.map { "_ = { (instance: \(product)) -> \($0) in instance }" }
        self.statements = checks + ["try container.register(\(callArguments.joined(separator: ", ")))\(chain)"]
        let suffix = arguments.name.map { " \($0)" } ?? ""
        self.keys = ([product] + arguments.forwardedTypes).map { $0 + suffix }
    }
}

/// Implements `@Provides`, a marker that `@Assembly` reads. It adds nothing.
public struct ProvidesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(FunctionDeclSyntax.self) else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node, message: AssemblyDiagnostic.providesNotOnFunction)
            ])
        }
        return []
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
    case duplicateProvider(String)
    case providesNotStatic
    case providesNeedsReturnType
    case providesNotOnFunction
    
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
        case .duplicateProvider(let key):
            "\(key) is already provided in this assembly; registration is last one wins, so this replaces it"
        case .providesNotStatic:
            "@Provides functions must be static"
        case .providesNeedsReturnType:
            "@Provides functions must return a concrete or 'any' type"
        case .providesNotOnFunction:
            "@Provides can only be applied to a static function"
        }
    }
    
    var diagnosticID: MessageID {
        switch self {
        case .notClassOrStruct: MessageID(domain: "AstrojectNexusMacros", id: "assemblyNotClassOrStruct")
        case .notType: MessageID(domain: "AstrojectNexusMacros", id: "assemblyNotType")
        case .requiresNotArray: MessageID(domain: "AstrojectNexusMacros", id: "assemblyRequiresNotArray")
        case .duplicateType: MessageID(domain: "AstrojectNexusMacros", id: "assemblyDuplicateType")
        case .duplicateProvider: MessageID(domain: "AstrojectNexusMacros", id: "assemblyDuplicateProvider")
        case .providesNotStatic: MessageID(domain: "AstrojectNexusMacros", id: "providesNotStatic")
        case .providesNeedsReturnType: MessageID(domain: "AstrojectNexusMacros", id: "providesNeedsReturnType")
        case .providesNotOnFunction: MessageID(domain: "AstrojectNexusMacros", id: "providesNotOnFunction")
        }
    }
    
    var severity: DiagnosticSeverity {
        switch self {
        case .duplicateType, .duplicateProvider: .warning
        default: .error
        }
    }
}
