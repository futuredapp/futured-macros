import SwiftSyntax
import SwiftSyntaxMacros

public enum CacheProjectionMacro {
    struct ParsedArguments {
        let stateTypeName: String
        let dataTypeName: String
    }

    /// Reads `state:` and `data:` arguments from the macro attribute, expecting
    /// each as a `T.self` metatype expression. Returns `nil` if the shape is
    /// wrong; the diagnostic is emitted by the caller so the caller can choose
    /// the right reporting node.
    static func parseArguments(from node: AttributeSyntax) -> ParsedArguments? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        var stateTypeName: String?
        var dataTypeName: String?

        for argument in arguments {
            guard let label = argument.label?.text else { continue }
            guard let typeName = baseTypeName(of: argument.expression) else { continue }
            switch label {
            case "state":
                stateTypeName = typeName
            case "data":
                dataTypeName = typeName
            default:
                continue
            }
        }

        guard let stateTypeName, let dataTypeName else {
            return nil
        }

        return ParsedArguments(stateTypeName: stateTypeName, dataTypeName: dataTypeName)
    }

    /// Extracts `ComponentState` from a `ComponentState.self` expression, or
    /// `nil` if the expression is anything else.
    private static func baseTypeName(of expression: ExprSyntax) -> String? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self) else {
            return nil
        }
        guard memberAccess.declName.baseName.text == "self" else {
            return nil
        }
        guard let base = memberAccess.base else {
            return nil
        }
        return base.trimmedDescription
    }
}
