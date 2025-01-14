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
        + emmitTransactionSupport(
            className: className(decl: declaration),
            storedVariables: storedVariable(members: declaration.memberBlock.members))
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
            struct __Versions {
            \(raw: storedVariableNames(members: members).map { "    var \($0): UInt = 0" }.joined(separator: "\n")  )
            }
            """
            ),
            DeclSyntax("private var __version: __Versions = .init()"),
        ]
    }

    private static func emmitSubsriptionSupport(className: String) -> [DeclSyntax] {
        [
            DeclSyntax(
            """
            private final class SubscriptionBox {
                internal init(
                    initialVersion: __Versions,
                    predicate: @escaping (_ oldValue: __Versions, _ newValue: __Versions) -> Bool
                ) {
                    self.initialVersion = initialVersion
                    self.predicate = predicate
                }
                
                private var initialVersion: __Versions
                private var predicate: (_ oldValue: __Versions, _ newValue: __Versions) -> Bool
                
                // calling convention
                var yeald: ((\(raw: className)) -> Void)!
                
                func responds(to newVersion: __Versions) -> Bool {
                    defer { 
                        initialVersion = newVersion 
                    }
                    return predicate(initialVersion, newVersion)
                }
            }
            """
            ),
            DeclSyntax("private var subscribtions: [SubscriptionBox] = []"),
            DeclSyntax(
            """
            func makeSubscriber(predicate: @escaping (_ oldValue: __Versions, _ newValue: __Versions) -> Bool) -> AsyncStream<\(raw: className)> {
                let subscriptionBox = SubscriptionBox(initialVersion: __version, predicate: predicate)
                let stream = AsyncStream<\(raw: className)> { continuation in
                    continuation.onTermination = { [weak self] _ in
                        self?.subscribtions.removeAll { 
                            $0 === subscriptionBox 
                        }
                    }
                    subscriptionBox.yeald = { 
                        continuation.yield($0) 
                    }
                }
                self.subscribtions.append(subscriptionBox)
                return stream
            }
            """
            )
        ]
    }

    private static func emmitTransactionSupport(className: String, storedVariables: [VariableDeclSyntax]) -> [DeclSyntax] {
        let variableDeclarations = storedVariables.compactMap(emmitProxyVariable(storedVariable:))
        let declStr =
            """
            final class ProxySetter {
                private var ref: \(className)
            
                internal init(ref: \(className)) {
                    self.ref = ref
                }
            
            \(variableDeclarations.joined(separator: "\n\n"))
            }
            """
        return [
            DeclSyntax(
                "\(raw: declStr)"
            ),
            DeclSyntax(
                """
                func transaction(eval: (ProxySetter) -> Void) {
                    eval(ProxySetter(ref: self))
                    evaluateSubscribtions()
                }
                """
            ),
            DeclSyntax(
                """
                private func evaluateSubscribtions() {
                    for subscribtion in subscribtions {
                        if subscribtion.responds(to: __version) {
                            subscribtion.yeald(self)
                        }
                    }
                }
                """
            )
        ]
    }

    private static func emmitProxyVariable(storedVariable: VariableDeclSyntax) -> String? {
        guard
            let binding = storedVariable.bindings.first,
            let name = binding.pattern.as(IdentifierPatternSyntax.self),
            let type = binding.typeAnnotation?.type
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
