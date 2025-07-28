//
//  Plugin.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 20.01.2025.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EnumIdentablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnumIdentableMacro.self,
    ]
}
