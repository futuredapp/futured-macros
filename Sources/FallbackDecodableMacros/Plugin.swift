import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FallbackDecodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FallbackDecodableMacro.self
    ]
}
