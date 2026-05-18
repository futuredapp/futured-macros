import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension FallbackDecodableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            // MemberExpansion has already diagnosed; stay silent here.
            return []
        }
        return [try ExtensionDeclSyntax("extension \(type): FallbackDecodable {}")]
    }
}
