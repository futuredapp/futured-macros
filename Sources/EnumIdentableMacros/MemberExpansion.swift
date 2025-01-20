//
//  MemberExpansion.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 20.01.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

extension EnumIdentableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Check if the declaration is an enum
        guard let declaration = declaration.as(EnumDeclSyntax.self) else {
            let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum)
            context.diagnose(enumError)
            return []
        }

        // Get all AST element which represent cases from the enum
        guard let enumCases = getAttachedEnumCases(declaration: declaration) else {
            let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustHaveCases)
            context.diagnose(enumError)
            return []
        }

        let caseIds = parseAttachedEnumCases(enumCases: enumCases)

            // Check if the enum has any parsed cases
        guard !caseIds.isEmpty else {
            let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustHaveCases)
            context.diagnose(enumError)
            return []
        }

        let casesContainsId = caseIds.contains { !$0.parameters.map(\.name).allSatisfy { $0 == "_" }}

            // If new enum hasn't associated values, we can use the String conforming for generating the rawValue
        let enumDefinition = casesContainsId ? "enum CaseID" : "enum CaseID: String"

        let enumSyntax = try EnumDeclSyntax(.init(stringLiteral: enumDefinition)) {
            for item in caseIds {
                EnumCaseDeclSyntax{
                    if case let parameters = item.parameters, !parameters.isEmpty, parameters.contains(where: { $0.name != "_" }) {
                        let parameters = parameters.compactMap {
                            if $0.name != "_" {
                                return "\($0.name): \($0.type)"
                            }
                            return nil
                        }.joined(separator: ", ")
                        EnumCaseElementSyntax(name: .identifier("\(item.caseName)(\(parameters))"))
                    } else {
                        EnumCaseElementSyntax(name: .identifier(item.caseName))
                    }
                }
            }
            if casesContainsId {
                try VariableDeclSyntax("var rawValue: String") {
                    try SwitchExprSyntax("switch self") {
                        for item in caseIds {
                            if case let parameters = item.parameters, !parameters.isEmpty, parameters.contains(where: { $0.name != "_" }) {
                                let parameters = parameters.map(\.name).filter { $0 != "_" }
                                SwitchCaseSyntax(stringLiteral:
                                    """
                                    case let .\(item.caseName)(\(parameters.joined(separator: ", "))):
                                        "\(item.caseName)-\(parameters.map { "\\(\($0))" }.joined(separator: "-"))"
                                    """
                                )
                            } else {
                                SwitchCaseSyntax(stringLiteral:
                                    """
                                    case .\(item.caseName):
                                        "\(item.caseName)"
                                    """
                                )
                            }
                        }
                    }
                }
            }
        }
        let idAccessor = try VariableDeclSyntax("var caseId: CaseID") {
            try SwitchExprSyntax("switch self") {
                for item in caseIds {
                    if case let parameters = item.parameters, !parameters.isEmpty, parameters.contains(where: { $0.name != "_" }) {
                        let definitionParameters = parameters.compactMap {
                            if $0.name != "_" {
                                return "\($0.name): \($0.name)"
                            }
                            return nil
                        }.joined(separator: ", ")
                        SwitchCaseSyntax(stringLiteral:
                            """
                            case let .\(item.caseName)(\(parameters.map(\.name).joined(separator: ", "))):
                                .\(item.caseName)(\(definitionParameters))
                            """
                        )
                    } else {
                        SwitchCaseSyntax(stringLiteral:
                            """
                            case .\(item.caseName):
                                .\(item.caseName)
                            """
                        )
                    }
                }
            }
        }
        return [
            DeclSyntax(enumSyntax),
            DeclSyntax(idAccessor)
        ]
    }

}
