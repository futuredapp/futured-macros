import SwiftSyntax

public enum AutoMockMacro {
    /// One protocol property requirement parsed into the pieces the expansion needs.
    struct PropertyRequirement {
        let name: String
        let type: TypeSyntax
        /// Default expression for this type, or `nil` if the type isn't trivially
        /// defaultable — in which case the property becomes an `init` parameter.
        let defaultExpression: String?

        var isInitParameter: Bool { defaultExpression == nil }
    }

    /// One protocol method requirement parsed into the pieces the expansion needs.
    struct MethodRequirement {
        let signature: FunctionDeclSyntax
        /// Body string to emit (e.g. `{}`, `{ false }`, `{ fatalError(...) }`).
        let body: String
    }

    static func mockClassName(for protocolName: String) -> String? {
        guard protocolName.hasSuffix("Protocol") else {
            return nil
        }
        let base = String(protocolName.dropLast("Protocol".count))
        return "\(base)Mock"
    }

    static func parseProperty(from variable: VariableDeclSyntax) -> PropertyRequirement? {
        guard let binding = variable.bindings.first else { return nil }
        guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return nil
        }
        guard let type = binding.typeAnnotation?.type else { return nil }
        return PropertyRequirement(
            name: identifier,
            type: type,
            defaultExpression: TypeDefaults.defaultExpression(for: type)
        )
    }

    static func parseMethod(from function: FunctionDeclSyntax) -> MethodRequirement {
        let returnType = function.signature.returnClause?.type
        let body = TypeDefaults.functionBody(returnType: returnType, mockClassReference: "Self.self")
        return MethodRequirement(signature: function, body: body)
    }
}
