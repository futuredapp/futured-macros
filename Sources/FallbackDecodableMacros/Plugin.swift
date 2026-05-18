import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DefaultableEnumPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DefaultableEnumMacro.self
    ]
}
