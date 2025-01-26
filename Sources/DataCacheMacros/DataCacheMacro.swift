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
        let attributeActor = node.arguments.flatMap { arguments -> String? in
            let isolationArg =  arguments.as(LabeledExprListSyntax.self)?.first { labeledExpr in
                labeledExpr.label?.text == "isolation"
            }

            guard let memberAccess = isolationArg?.expression.as(MemberAccessExprSyntax.self) else {
                return nil
            }

            guard let base = memberAccess.base else {
                return nil
            }

            return "\(base)"
        }


        return makeVersionsStruct(members: declaration.memberBlock.members)
        + emmitSubsriptionSupport(className: className(decl: declaration), actor: attributeActor)
        + emmitTransactionSupport(className: className(decl: declaration))
    }

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
            struct _Versions: Hashable {
            \(raw: storedVariableNames(members: members).map { "    var \($0): UInt = 0" }.joined(separator: "\n")  )
            }
            """
            ),
            DeclSyntax("private var _version: _Versions = .init()"),
        ]
    }

    private static func emmitSubsriptionSupport(className: String, actor: String?) -> [DeclSyntax] {
        var makePattern =
        """
        func makeSubscriber(predicate: @escaping (_ oldValue: _Versions, _ newValue: _Versions) -> Bool) -> AsyncStream<\(className)> {
            let (stream, continuation) = AsyncStream.makeStream(of: \(className).self)
            let box = SubscriptionBox(
                initialVersion: self._version,
                continuation: continuation,
                predicate: predicate
            )
        
            continuation.onTermination = { [weak self] _ in
        
        """
        if let actor {
            makePattern +=
            """
                    Task { @\(actor) in 
                        self?._subscribtions.removeAll {
                            $0 === box
                        }
                    }
            """
        } else {
            makePattern +=
            """
                    self?._subscribtions.removeAll {
                        $0 === box
                    }
            """
        }
        makePattern +=
        """
            }
            defer { continuation.yield(self) }
            self._subscribtions.append(box)
            return stream
        }
        """

        return [
            DeclSyntax("private var _subscribtions: [SubscriptionBox<\(raw: className)>] = []"),
            DeclSyntax(stringLiteral: makePattern)
        ]
    }

    private static func emmitTransactionSupport(className: String) -> [DeclSyntax] {
        return [
            DeclSyntax(
                """
                func applyChanges(during block: () -> Void) {
                    block()
                    for subscribtion in _subscribtions {
                        subscribtion.emmit(cache: self, ifDiffers: self._version)
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
