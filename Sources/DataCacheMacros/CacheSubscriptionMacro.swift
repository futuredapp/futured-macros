//
//  CacheSubscriptionMacro.swift
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

public struct CacheSubscriptionMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        var cacheNameExr: String?
        var properties: [String] = []

        for listItem in node.argumentList {
            if cacheNameExr == nil {
                if
                    let labeled = listItem.as(LabeledExprSyntax.self),
                    labeled.label?.text == "on"
                {
                    cacheNameExr = "\(labeled.expression)"
                } else {
                    return ExprSyntax("")
                }
            } else if properties.count == 0 {
                if
                    let labeled = listItem.as(LabeledExprSyntax.self),
                    labeled.label?.text == "properties",
                    let kpExpr = labeled.expression.as(KeyPathExprSyntax.self)
                {
                    properties = ["\(kpExpr.components)"]
                } else {
                    return ExprSyntax("")
                }
            } else {
                if
                    let labeled = listItem.as(LabeledExprSyntax.self),
                    let kpExpr = labeled.expression.as(KeyPathExprSyntax.self)
                {
                    properties.append("\(kpExpr.components)")
                } else {
                    return ExprSyntax("")
                }
            }
        }

        guard let cacheNameExr, !properties.isEmpty else {
            return ExprSyntax("")
        }

        return ExprSyntax(
            """
            \(raw: cacheNameExr).makeSubscriber(
                predicate: { 
                    \( raw: properties.map { "$0\($0) != $1\($0)" }.joined(separator: " || ") ) 
                }
            )
            """
        )
    }
}
