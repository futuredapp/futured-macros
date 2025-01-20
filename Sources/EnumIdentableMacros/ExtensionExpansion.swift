//
//  ExtensionMacro.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 20.01.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

extension EnumIdentableMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum)
            context.diagnose(enumError)
            return []
        }

        let protocolNames: Set<String> = Set(protocols.map { "\($0)" } )

        let equatableConformance = try ExtensionDeclSyntax(
            """
            extension \(type): Equatable {
                static func == (lhs: Self, rhs: Self) -> Bool {
                    lhs.id == rhs.id
                }
            }
            """
        )

        let hashableConformance = try ExtensionDeclSyntax(
            """
            extension \(type): Hashable {
                func hash(into hasher: inout Hasher) {
                    hasher.combine(id)
                }
            }
            """
        )

        let identifiableConformance = try ExtensionDeclSyntax(
            """
            extension \(type): Identifiable {
                var id: String {
                    self.caseId.rawValue
                }
            }
            """
        )


        // There is probably bug in Swift Tests where conformances are not passed down. Should investigate.
        return []
            + (protocolNames.contains("Equatable") ? [equatableConformance] : [])
            + (protocolNames.contains("Hashable") ? [hashableConformance] : [])
            + (protocolNames.contains("Identifiable") ? [identifiableConformance] : [])
    }
}
