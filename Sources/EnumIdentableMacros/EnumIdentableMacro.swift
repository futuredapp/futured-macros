//
//  EnumIdentableMacro.swift
//
//
//  Created by Simon Sestak on 31/07/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct EnumIdentableMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context) throws -> [SwiftSyntax.DeclSyntax] where Declaration : SwiftSyntax.DeclGroupSyntax, Context : SwiftSyntaxMacros.MacroExpansionContext {

            // Check if the declaration is an enum
            guard let declaration = declaration.as(EnumDeclSyntax.self) else {
                let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum)
                context.diagnose(enumError)
                return []
            }

            // Get all AST element which represent cases from the enum
            guard let enumCases: [SyntaxProtocol] = declaration.memberBlock
                .children(viewMode: .fixedUp).filter({ $0.kind == .memberDeclList })
                .first?
                .children(viewMode: .fixedUp).filter({ $0.kind == SyntaxKind.memberDeclListItem })
                .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseDecl })})
                .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseElementList })})
                .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseElement })})
            else {
                let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustHaveCases)
                context.diagnose(enumError)
                return []
            }

            // Get all cases names with their parameters
            let caseIds: [(case: String, parameters: [(name: String, type: String)])] = enumCases.compactMap { enumCase in
                guard let firstToken = enumCase.firstToken(viewMode: .fixedUp) else {
                    return nil
                }

                guard case let .identifier(id) = firstToken.tokenKind else {
                    return nil
                }

                let enumCaseParameterClause = enumCase.children(viewMode: .fixedUp).filter{ $0.kind == .enumCaseParameterClause }
                let enumCaseParameterList = enumCaseParameterClause.flatMap { $0.children(viewMode: .fixedUp).filter { $0.kind == .enumCaseParameterList }}
                let enumCaseParameter = enumCaseParameterList.flatMap { $0.children(viewMode: .fixedUp).filter { $0.kind == .enumCaseParameter }}
                let parametersTokens = enumCaseParameter.compactMap {
                    let parameterName = $0.firstToken(viewMode: .fixedUp)
                    let parameterType = $0.lastToken(viewMode: .fixedUp)
                    return (parameterName, parameterType)
                }
                // Check if the case contains an parameter that contains "id"
                let parameters: [(name: String, type: String)] = parametersTokens.compactMap { name, type in
                    if case let .identifier(idName) = name?.tokenKind,
                       idName.lowercased().contains("id"),
                       case let .identifier(typeName) = type?.tokenKind {
                        return (name: idName, type: typeName)
                    }
                    return (name: "_", type: "_")
                }
                return (id, parameters)
            }

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
                            EnumCaseElementSyntax(name: .identifier("\(item.case)(\(parameters))"))
                        } else {
                            EnumCaseElementSyntax(name: .identifier(item.case))
                        }
                    }
                }
                if casesContainsId {
                    try VariableDeclSyntax("var rawValue: String") {
                        try SwitchExprSyntax("switch self") {
                            for item in caseIds {
                                if case let parameters = item.parameters, !parameters.isEmpty, parameters.contains(where: { $0.name != "_" }) {
                                    let parameters = parameters.map(\.name).filter { $0 != "_" }.joined(separator: ", ")
                                    SwitchCaseSyntax(stringLiteral:
                                        """
                                        case let .\(item.case)(\(parameters)):
                                            "\(item.case)-\\(\(parameters))"
                                        """
                                    )
                                } else {
                                    SwitchCaseSyntax(stringLiteral:
                                        """
                                        case .\(item.case):
                                            "\(item.case)"
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
                                case let .\(item.case)(\(parameters.map(\.name).joined(separator: ", "))):
                                    .\(item.case)(\(definitionParameters))
                                """
                            )
                        } else {
                            SwitchCaseSyntax(stringLiteral:
                                """
                                case .\(item.case):
                                    .\(item.case)
                                """
                            )
                        }
                    }
                }
            }
            let identifierVariable = try VariableDeclSyntax("var id: String") {
                """
                self.caseId.rawValue
                """
            }
            let hashableConformance = try FunctionDeclSyntax("func hash(into hasher: inout Hasher)") {
                """
                hasher.combine(id)
                """
            }
            let comparableConformance = try FunctionDeclSyntax("static func == (lhs: Self, rhs: Self) -> Bool") {
                """
                lhs.id == rhs.id
                """
            }

            return [
                DeclSyntax(enumSyntax),
                DeclSyntax(idAccessor),
                DeclSyntax(identifierVariable),
                DeclSyntax(hashableConformance),
                DeclSyntax(comparableConformance)
            ]
        }

    public enum Diagnostics: String, DiagnosticMessage {

        case mustBeEnum, mustHaveCases

        public var message: String {
            switch self {
            case .mustBeEnum:
                return "`@EnumIdentableMacro` can only be applied to an `enum`"
            case .mustHaveCases:
                return "`@EnumIdentableMacro` can only be applied to an `enum` with `case` statements"
            }
        }

        public var diagnosticID: MessageID {
            MessageID(domain: "EnumIdentableMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity { .error }
    }
}

@main
struct EnumIdentablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnumIdentableMacro.self,
    ]
}
