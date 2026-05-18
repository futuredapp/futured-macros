import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension CacheProjectionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            // The MemberMacro pass already emitted the diagnostic; just bail.
            return []
        }

        let conformanceExtension = try ExtensionDeclSyntax(
            "extension \(type): CacheProjection {}"
        )

        return [conformanceExtension]
    }
}
