import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct FlattenPropertiesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. Validate that the macro is applied to a VariableDeclSyntax (var/let property)
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let binding = variableDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw CustomMacroError.message("FlattenProperties can only be applied to a 'var' or 'let' property declaration.")
        }

        // Get the name of the property the macro is attached to (e.g., "myDataProperty")
        let sourcePropertyName = identifier.identifier.text

        // 2. Extract the property names to flatten from the macro arguments
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw CustomMacroError.message("FlattenProperties macro requires at least one property name argument.")
        }

        var propertiesToFlatten: [String] = []
        for argument in arguments {
            if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
               let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                propertiesToFlatten.append(segment.content.text)
            } else {
                context.diagnose(
                    Diagnostic(
                        node: argument.expression,
                        message: MacroDiagnostic.requiresStringLiteral
                    )
                )
            }
        }

        if propertiesToFlatten.isEmpty {
            throw CustomMacroError.message("FlattenProperties macro requires at least one property name to flatten.")
        }

        // 3. Generate forwarding properties for each extracted name
        var generatedMembers: [DeclSyntax] = []
        for name in propertiesToFlatten {
            let accessor: String
            // Heuristic for computed/read-only properties:
            // Still uses patterns. If your nested type has custom mutability,
            // you might need a more sophisticated way (e.g., passing a struct
            // of {name: String, isMutable: Bool} as arguments).
            if name.hasSuffix("Ids") || name.hasPrefix("is") || name.hasPrefix("computed") { // Added "computed" prefix as a heuristic
                accessor = """
                get { \(sourcePropertyName).\(name) }
                """
            } else { // Assume most properties are mutable stored properties
                accessor = """
                get { \(sourcePropertyName).\(name) }
                set { \(sourcePropertyName).\(name) = newValue }
                """
            }

            generatedMembers.append(
                """
                var \(raw: name) { \(raw: accessor) }
                """
            )
        }

        return generatedMembers
    }
}

// Custom error and diagnostic messages (keep the same)
enum CustomMacroError: CustomStringConvertible, Error {
    case message(String)

    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}

fileprivate enum MacroDiagnostic: String, DiagnosticMessage {
    case requiresStringLiteral

    var message: String {
        switch self {
        case .requiresStringLiteral:
            return "Arguments to @FlattenProperties must be string literals."
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "FlattenPropertiesMacro", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
}

@main
struct FlattenPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlattenPropertiesMacro.self,
    ]
}
