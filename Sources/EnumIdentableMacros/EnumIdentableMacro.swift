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

            guard let declaration = declaration.as(EnumDeclSyntax.self) else {
                let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum)
                context.diagnose(enumError)
                return []
            }

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

            let caseIds: [String] = enumCases.compactMap { enumCase in
                guard let firstToken = enumCase.firstToken(viewMode: .fixedUp) else {
                    return nil
                }

                guard case let .identifier(id) = firstToken.tokenKind else {
                    return nil
                }

                return id
            }

            guard !caseIds.isEmpty else {
                let enumError = Diagnostic(node: node._syntaxNode, message: Diagnostics.mustHaveCases)
                context.diagnose(enumError)
                return []
            }

            let enumSyntax = try EnumDeclSyntax("enum CaseID: String, Hashable, CaseIterable, CustomStringConvertible") {
                for caseId in caseIds {
                    EnumCaseDeclSyntax.init {
                        EnumCaseElementSyntax.init(name: .identifier(caseId))
                    }
                }
                try VariableDeclSyntax("var description: String") {
                    """
                    self.rawValue
                    """
                }
            }
            let idAccessor = try VariableDeclSyntax("var caseId: CaseID") {
                try SwitchExprSyntax("switch self") {
                    for caseId in caseIds {
                        SwitchCaseSyntax(stringLiteral:
                            """
                            case .\(caseId):
                                .\(caseId)
                            """
                        )
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
