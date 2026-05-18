import SwiftDiagnostics

extension FallbackDecodableMacro {
    public enum Diagnostics: DiagnosticMessage {
        case mustBeEnum
        case unknownFallbackCase(name: String, available: String)
        case fallbackCaseInvalidArity
        case noRawTypeForBranchA
        case mixedRawAndAssociated
        case branchBRequiresStringRaw
        case branchBKnownCaseHasAssociatedValue(name: String)

        public var message: String {
            switch self {
            case .mustBeEnum:
                "`@FallbackDecodable` can only be applied to an `enum`"
            case let .unknownFallbackCase(name, available):
                "Case `.\(name)` does not exist on this enum. Available cases: \(available)"
            case .fallbackCaseInvalidArity:
                "Fallback case must have zero or one associated value"
            case .noRawTypeForBranchA:
                "Zero-arity fallback requires an explicit raw type on the enum (e.g. `enum X: String`)"
            case .mixedRawAndAssociated:
                "Cannot combine an explicit raw type with an associated-value fallback case"
            case .branchBRequiresStringRaw:
                "Associated-value fallback case must use `String` (other types not supported in v1)"
            case let .branchBKnownCaseHasAssociatedValue(name):
                "Case `.\(name)` has an associated value; only the fallback case may carry one"
            }
        }

        public var diagnosticID: MessageID {
            let id: String = switch self {
            case .mustBeEnum: "mustBeEnum"
            case .unknownFallbackCase: "unknownFallbackCase"
            case .fallbackCaseInvalidArity: "fallbackCaseInvalidArity"
            case .noRawTypeForBranchA: "noRawTypeForBranchA"
            case .mixedRawAndAssociated: "mixedRawAndAssociated"
            case .branchBRequiresStringRaw: "branchBRequiresStringRaw"
            case .branchBKnownCaseHasAssociatedValue: "branchBKnownCaseHasAssociatedValue"
            }
            return MessageID(domain: "FallbackDecodableMacro", id: id)
        }

        public var severity: DiagnosticSeverity { .error }
    }
}
