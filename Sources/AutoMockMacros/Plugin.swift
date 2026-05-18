import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AutoMockPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoMockMacro.self
    ]
}
