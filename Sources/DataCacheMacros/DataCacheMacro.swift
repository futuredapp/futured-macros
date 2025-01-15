//
//  DataCacheMacro.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 13.01.2025.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct DataCacheMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax] where
    Declaration : SwiftSyntax.DeclGroupSyntax,
    Context : SwiftSyntaxMacros.MacroExpansionContext
    {
        return makeVersionsStruct(members: declaration.memberBlock.members)
        + emmitSubsriptionSupport(className: className(decl: declaration))
        + emmitTransactionSupport(className: className(decl: declaration))
    }

        // todo
    private static func className<Declaration: SwiftSyntax.DeclGroupSyntax>(decl: Declaration) -> String! {
        guard let clsDecl = decl.as(ClassDeclSyntax.self) else {
            return nil
        }

        return clsDecl.name.text
    }

        // if some variables are undesirable, you can add filter to this method
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

    private static func storedVariableNames(members: MemberBlockItemListSyntax) -> [String] {
        storedVariable(members: members).compactMap { varDecl in
            guard
                let ident = varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)
            else {
                return nil
            }

            return ident.identifier.text
        }
    }

    private static func makeVersionsStruct(members: MemberBlockItemListSyntax) -> [DeclSyntax] {
        [
            DeclSyntax(
            """
            struct _Versions {
            \(raw: storedVariableNames(members: members).map { "    var \($0): UInt = 0" }.joined(separator: "\n")  )
            }
            """
            ),
            DeclSyntax("private var _version: _Versions = .init()"),
        ]
    }

    private static func emmitSubsriptionSupport(className: String) -> [DeclSyntax] {
        [
            DeclSyntax("private var _subscribtions: [SubscriptionBox<Self>] = []"),
            DeclSyntax(
            """
            func makeSubscriber(predicate: @escaping (_ oldValue: _Versions, _ newValue: _Versions) -> Bool) -> AsyncStream<\(raw: className)> {
                let subscriptionBox = SubscriptionBox(initialVersion: _version, predicate: predicate)
                let stream = AsyncStream<\(raw: className)> { continuation in
                    continuation.onTermination = { [weak self] _ in
                        self?._subscribtions.removeAll { 
                            $0 === subscriptionBox 
                        }
                    }
                    subscriptionBox.yeald = { 
                        continuation.yield($0) 
                    }
                }
                self._subscribtions.append(subscriptionBox)
                return stream
            }
            """
            )
        ]
    }

    private static func emmitTransactionSupport(className: String) -> [DeclSyntax] {
        return [
            DeclSyntax(
                """
                func applyChanges(during block: () -> Void) {
                    block()
                    for subscribtion in _subscribtions {
                        if subscribtion.responds(to: _version) {
                            subscribtion.yeald(self)
                        }
                    }
                }
                """
            )
        ]
    }
}

extension DataCacheMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard member.is(VariableDeclSyntax.self) else { return [] }
        return ["@VersionedProperty"]
    }
}

extension DataCacheMacro: ExtensionMacro {
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

        return [
            try? ExtensionDeclSyntax(
                """
                extension \(raw: classDecl.name.text): VersionedDataCache { }
                """
            )
        ].compactMap(\.self)
    }


}
