//
//  VersionedPropertyMacro.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 14.01.2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct VersionedPropertyMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let ident = declaration.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self) else {
            return []
        }
        return [
            """
            @storageRestrictions(initializes: _\(raw: ident.identifier.text))
            init(newValue)  {
                self._\(raw: ident.identifier.text) = newValue
            }
            """,
            """
            get {
                self._\(raw: ident.identifier.text)
            }
            """,
            """
            set {
                if newValue != self._\(raw: ident.identifier.text) {
                    self.__version.\(raw: ident.identifier.text) = self.__version.\(raw: ident.identifier.text) &+ 1
                }
                self._\(raw: ident.identifier.text) = newValue
            }
            """
        ]
    }
}
