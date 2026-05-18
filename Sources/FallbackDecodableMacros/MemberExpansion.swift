import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension FallbackDecodableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node._syntaxNode, message: Diagnostics.mustBeEnum))
            return []
        }

        guard let fallbackName = parseFallbackCaseName(node) else {
            // Required argument — compiler catches missing arg at the call site.
            return []
        }

        let cases = parseCases(enumDecl)
        guard let fallbackCase = cases.first(where: { $0.name == fallbackName }) else {
            let available = cases.map { ".\($0.name)" }.joined(separator: ", ")
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.unknownFallbackCase(name: fallbackName, available: available)
            ))
            return []
        }

        if fallbackCase.associatedTypes.count > 1 {
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.fallbackCaseInvalidArity
            ))
            return []
        }

        let rawType = parseRawType(enumDecl)

        if fallbackCase.associatedTypes.isEmpty {
            return try branchA(
                node: node,
                fallbackName: fallbackName,
                rawType: rawType,
                in: context
            )
        } else {
            return try branchB(
                node: node,
                fallbackName: fallbackName,
                fallbackCase: fallbackCase,
                cases: cases,
                rawType: rawType,
                in: context
            )
        }
    }

    /// Zero-arity fallback case + explicit raw type on the enum.
    private static func branchA(
        node: AttributeSyntax,
        fallbackName: String,
        rawType: String?,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let rawType else {
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.noRawTypeForBranchA
            ))
            return []
        }
        return [
            """
            nonisolated static func fallback(for _: \(raw: rawType)) -> Self {
                .\(raw: fallbackName)
            }
            """
        ]
    }

    /// One-arity fallback case (e.g. `case unknown(String)`), no explicit raw type.
    /// Synthesises `init?(rawValue:)` + `rawValue` using case-name-as-raw-value
    /// for known cases, plus the rich `fallback(for:)`.
    private static func branchB(
        node: AttributeSyntax,
        fallbackName: String,
        fallbackCase: ParsedCase,
        cases: [ParsedCase],
        rawType: String?,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if rawType != nil {
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.mixedRawAndAssociated
            ))
            return []
        }
        let associatedType = fallbackCase.associatedTypes[0]
        guard associatedType == "String" else {
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.branchBRequiresStringRaw
            ))
            return []
        }

        let knownCases = cases.filter { $0.name != fallbackName }
        for knownCase in knownCases where !knownCase.associatedTypes.isEmpty {
            context.diagnose(Diagnostic(
                node: node._syntaxNode,
                message: Diagnostics.branchBKnownCaseHasAssociatedValue(name: knownCase.name)
            ))
            return []
        }

        let initCases = knownCases
            .map { #"        case "\#($0.name)": self = .\#($0.name)"# }
            .joined(separator: "\n")
        let rawValueKnownCases = knownCases
            .map { #"        case .\#($0.name): return "\#($0.name)""# }
            .joined(separator: "\n")

        let initDecl: DeclSyntax = """
        nonisolated init?(rawValue: String) {
            switch rawValue {
        \(raw: initCases)
            default: return nil
            }
        }
        """

        let rawValueDecl: DeclSyntax = """
        nonisolated var rawValue: String {
            switch self {
        \(raw: rawValueKnownCases)
            case let .\(raw: fallbackName)(raw): return raw
            }
        }
        """

        let fallbackDecl: DeclSyntax = """
        nonisolated static func fallback(for raw: String) -> Self {
            .\(raw: fallbackName)(raw)
        }
        """

        return [initDecl, rawValueDecl, fallbackDecl]
    }
}
