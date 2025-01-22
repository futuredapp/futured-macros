//
//  EnumIdentableMacro.swift
//
//
//  Created by Simon Sestak on 31/07/2024.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public enum EnumIdentableMacro {
    struct AttachedEnumCase {
        struct Parameter {
            let name: String
            let type: String
        }
        
        let caseName: String
        let parameters: [Parameter]
    }

    static func getAttachedEnumCases(declaration enumDecl: EnumDeclSyntax) -> [SyntaxProtocol]? {
        enumDecl.memberBlock
            .children(viewMode: .fixedUp).filter({ $0.kind == .memberDeclList })
            .first?
            .children(viewMode: .fixedUp).filter({ $0.kind == SyntaxKind.memberDeclListItem })
            .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseDecl })})
            .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseElementList })})
            .flatMap({ $0.children(viewMode: .fixedUp).filter({ $0.kind == .enumCaseElement })})
    }

    /// - ToDo:  Fix Reporting
    static func parseAttachedEnumCases(enumCases: [SyntaxProtocol]) -> [AttachedEnumCase] {
        enumCases.compactMap { enumCase -> AttachedEnumCase? in
            guard let firstToken = enumCase.firstToken(viewMode: .fixedUp) else {
                return nil
            }

            guard case let .identifier(id) = firstToken.tokenKind else {
                return nil
            }

            let enumCaseParameterClause = enumCase.children(viewMode: .fixedUp).filter{ $0.kind == .enumCaseParameterClause }
            let enumCaseParameterList = enumCaseParameterClause.flatMap { $0.children(viewMode: .fixedUp).filter { $0.kind == .enumCaseParameterList }}
            let enumCaseParameter: [SyntaxChildren.Element] = enumCaseParameterList.flatMap { $0.children(viewMode: .fixedUp).filter { $0.kind == .enumCaseParameter }}
            let parametersTokens = enumCaseParameter.compactMap { item -> (TokenSyntax?, TypeSyntax)? in
                guard
                    let item = item.as(EnumCaseParameterSyntax.self)
                else {
                    return nil
                }
                return (item.firstName, item.type)
            }
                // Check if the case contains an parameter that contains "id"
            let parameters: [AttachedEnumCase.Parameter] = parametersTokens.compactMap { name, type in
                if
                    case let .identifier(idName) = name?.tokenKind,
                    idName.lowercased().contains("id")
                {
                    return .init(name: idName, type: "\(type)")
                }
                return .init(name: "_", type: "_")
            }
            return .init(caseName: id, parameters: parameters)
        }
    }
}
