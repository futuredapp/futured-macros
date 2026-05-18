import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension AutoMockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeProtocol))
            return []
        }

        let protocolName = protocolDecl.name.text

        guard let mockName = mockClassName(for: protocolName) else {
            context.diagnose(Diagnostic(node: protocolDecl.name, message: Diagnostics.protocolNameMustEndInProtocol))
            return []
        }

        var properties: [PropertyRequirement] = []
        var methods: [MethodRequirement] = []

        for member in protocolDecl.memberBlock.members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                guard let property = parseProperty(from: variable) else { continue }
                properties.append(property)
                continue
            }
            if let function = member.decl.as(FunctionDeclSyntax.self) {
                methods.append(parseMethod(from: function))
                continue
            }
            if member.decl.is(SubscriptDeclSyntax.self)
                || member.decl.is(AssociatedTypeDeclSyntax.self)
                || member.decl.is(InitializerDeclSyntax.self) {
                context.diagnose(Diagnostic(node: member._syntaxNode, message: Diagnostics.unsupportedRequirement))
                return []
            }
        }

        let initParameters = properties.filter(\.isInitParameter)

        let propertyDecls: String = properties
            .map { property in
                if let defaultExpr = property.defaultExpression {
                    "    var \(property.name): \(property.type.trimmedDescription) = \(defaultExpr)"
                } else {
                    "    var \(property.name): \(property.type.trimmedDescription)"
                }
            }
            .joined(separator: "\n")

        let initSection: String = if initParameters.isEmpty {
            ""
        } else {
            renderInit(parameters: initParameters)
        }

        let methodDecls: String = methods
            .map { renderMethod($0) }
            .joined(separator: "\n\n")

        // Determine class-name reference for fatalError messages. Using "Self.self" is fine — at
        // runtime it resolves to the mock class.

        var classBody: [String] = []
        classBody.append("    var onEvent: (Event) -> Void = { _ in }")
        if !propertyDecls.isEmpty {
            classBody.append(propertyDecls)
        }
        if !initSection.isEmpty {
            classBody.append(initSection)
        }
        if !methodDecls.isEmpty {
            classBody.append(methodDecls)
        }

        let mockClass: String =
            """
            #if DEBUG
            @Observable
            final class \(mockName): \(protocolName) {
            \(classBody.joined(separator: "\n\n"))
            }
            #endif
            """

        return [DeclSyntax(stringLiteral: mockClass)]
    }

    private static func renderInit(parameters: [PropertyRequirement]) -> String {
        let paramLines = parameters
            .map { "        \($0.name): \($0.type.trimmedDescription)" }
            .joined(separator: ",\n")
        let assignments = parameters
            .map { "        self.\($0.name) = \($0.name)" }
            .joined(separator: "\n")
        return """
            init(
        \(paramLines)
            ) {
        \(assignments)
            }
        """
    }

    private static func renderMethod(_ method: MethodRequirement) -> String {
        let signature = method.signature
        let name = signature.name.text
        let parameters = renderMethodParameters(signature.signature.parameterClause.parameters)
        let effects = renderEffectSpecifiers(signature.signature.effectSpecifiers)
        let returnClause = signature.signature.returnClause.map { " -> \($0.type.trimmedDescription)" } ?? ""
        let header = "    func \(name)(\(parameters))\(effects)\(returnClause)"
        return "\(header) \(method.body)"
    }

    private static func renderMethodParameters(_ parameters: FunctionParameterListSyntax) -> String {
        // Preserve the external label, replace the internal name with `_` to suppress
        // unused-parameter warnings in the empty stub bodies.
        parameters
            .map { parameter in
                let externalLabel = parameter.firstName.text
                let type = parameter.type.trimmedDescription
                if externalLabel == "_" {
                    return "_: \(type)"
                }
                return "\(externalLabel) _: \(type)"
            }
            .joined(separator: ", ")
    }

    private static func renderEffectSpecifiers(_ effects: FunctionEffectSpecifiersSyntax?) -> String {
        guard let effects else { return "" }
        var parts: [String] = []
        if effects.asyncSpecifier != nil {
            parts.append("async")
        }
        if let throwsClause = effects.throwsClause {
            if let thrownType = throwsClause.type {
                parts.append("throws(\(thrownType.trimmedDescription))")
            } else {
                parts.append("throws")
            }
        }
        return parts.isEmpty ? "" : " \(parts.joined(separator: " "))"
    }
}
