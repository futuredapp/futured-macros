import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension CacheProjectionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeStruct))
            return []
        }

        guard let arguments = parseArguments(from: node) else {
            context.diagnose(Diagnostic(node: node._syntaxNode, message: Diagnostics.argumentNotMetatype))
            return []
        }

        let stateType = arguments.stateTypeName
        let dataType = arguments.dataTypeName

        let stateProperty: DeclSyntax = "var state: \(raw: stateType)"
        let dataProperty: DeclSyntax = "@ProxyMembers var data: \(raw: dataType)"
        let emptyFactory: DeclSyntax =
            """
            static func empty(state: \(raw: stateType)) -> Self {
                Self(state: state, data: .mock)
            }
            """

        return [stateProperty, dataProperty, emptyFactory]
    }
}
