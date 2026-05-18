import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CacheProjectionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CacheProjectionMacro.self
    ]
}
