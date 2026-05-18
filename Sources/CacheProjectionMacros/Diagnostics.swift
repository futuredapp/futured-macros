import SwiftDiagnostics

extension CacheProjectionMacro {
    public enum Diagnostics: String, DiagnosticMessage {
        case mustBeStruct
        case argumentNotMetatype

        public var message: String {
            switch self {
            case .mustBeStruct:
                "`@CacheProjection` can only be applied to a `struct`"
            case .argumentNotMetatype:
                "`@CacheProjection` requires metatype arguments (e.g. `state: ComponentState.self`, `data: HomeData.self`)"
            }
        }

        public var diagnosticID: MessageID {
            MessageID(domain: "CacheProjectionMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity { .error }
    }
}
