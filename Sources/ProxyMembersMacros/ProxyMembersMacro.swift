import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct ProxyMembersMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let property = declaration.as(VariableDeclSyntax.self) else {
            // Error if not attached to a var/let
            let diagnostic = Diagnostic(node: declaration, message: ProxyMembersMacroError.requiresProperty)
            context.diagnose(diagnostic)
            throw ProxyMembersMacroError.requiresProperty
        }

        guard let binding = property.bindings.first, property.bindings.count == 1 else {
            // Error if it's a complex binding like `var (a, b)`
            let diagnostic = Diagnostic(node: property.bindings, message: ProxyMembersMacroError.requiresSingleBinding)
            context.diagnose(diagnostic)
            throw ProxyMembersMacroError.requiresSingleBinding
        }

        guard let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            // This is a different flavor of the single binding error.
            let diagnostic = Diagnostic(node: binding.pattern, message: ProxyMembersMacroError.requiresSingleBinding)
            context.diagnose(diagnostic)
            throw ProxyMembersMacroError.requiresSingleBinding
        }

        guard let propertyType = binding.typeAnnotation?.type else {
            // Error if the type is missing, e.g., `var data`
            let diagnostic = Diagnostic(node: binding.pattern, message: ProxyMembersMacroError.requiresTypeAnnotation)
            context.diagnose(diagnostic)
            throw ProxyMembersMacroError.requiresTypeAnnotation
        }

        var generatedDecls: [DeclSyntax] = []

        let getOnlySubscript: DeclSyntax =
            """
            subscript<Value>(dynamicMember keyPath: KeyPath<\(propertyType), Value>) -> Value {
                \(raw: propertyName)[keyPath: keyPath]
            }
            """

        generatedDecls.append(getOnlySubscript)

        if property.bindingSpecifier.text == "var" {
            let getSetSubscript: DeclSyntax =
            """
            subscript<Value>(dynamicMember keyPath: WritableKeyPath<\(propertyType), Value>) -> Value {
                get { \(raw: propertyName)[keyPath: keyPath] }
                set { \(raw: propertyName)[keyPath: keyPath] = newValue }
            }
            """

            generatedDecls.append(getSetSubscript)
        }

        return generatedDecls
    }
}

enum ProxyMembersMacroError: String, DiagnosticMessage, Error {
    case requiresProperty = "@ProxyMembersMembers can only be attached to a property declaration."
    case requiresSingleBinding = "@ProxyMembersMembers can only be attached to a property with a single variable."
    case requiresTypeAnnotation = "The property with @ProxyMembersMembers must have an explicit type annotation."

    // Protocol requirements for DiagnosticMessage
    var message: String { self.rawValue }
    var diagnosticID: MessageID { MessageID(domain: "FuturedMacros", id: self.rawValue) }
    var severity: DiagnosticSeverity { .error }
}

@main
struct ProxyMembersPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProxyMembersMacro.self,
    ]
}
