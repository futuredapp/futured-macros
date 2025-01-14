//
//  CacheMain.swift
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

@main
struct DataCachePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DataCacheMacro.self,
        CacheSubscriptionMacro.self,
        VersionedPropertyMacro.self,
    ]
}
