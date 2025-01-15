//
//  ProxySetterMacro.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 15.01.2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct ProxySetterMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            return []
        }

        let variableDeclarations = storedVariable(
            members: declaration.memberBlock.members
        ).compactMap(emmitProxyVariable(storedVariable:))

        let declStr =
            """
                final class Proxy: ProxyObject {
                    private var ref: \(classDecl.name.text)
                
                    init(ref: \(classDecl.name.text)) {
                        self.ref = ref
                    }
                
            \(variableDeclarations.joined(separator: "\n\n"))
                }
            """

        return [
            try? ExtensionDeclSyntax(
                """
                extension \(raw: classDecl.name.text): ProxySettable {
                \(raw: declStr)
                }
                """
            )
        ].compactMap(\.self)
    }

    private static func storedVariable(members: MemberBlockItemListSyntax) -> [VariableDeclSyntax] {
        members.compactMap { member in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self)
            else {
                return nil
            }

            return varDecl
        }
    }

    private static func emmitProxyVariable(storedVariable: VariableDeclSyntax) -> String? {
        guard
            let binding = storedVariable.bindings.first,
            let name = binding.pattern.as(IdentifierPatternSyntax.self),
            let type = binding.typeAnnotation?.type,
            !"\(name)".hasPrefix("_")
        else {
            return nil
        }

        return  """
                        var \(name): \(type) {
                            get { 
                                ref.\(name)
                            }
                            set {
                                ref.\(name) = newValue
                            }
                        }
                """
    }


}
