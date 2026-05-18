import SwiftDiagnostics

extension AutoMockMacro {
    public enum Diagnostics: String, DiagnosticMessage {
        case mustBeProtocol
        case protocolNameMustEndInProtocol
        case unsupportedRequirement

        public var message: String {
            switch self {
            case .mustBeProtocol:
                "`@AutoMock` can only be applied to a `protocol`"
            case .protocolNameMustEndInProtocol:
                "`@AutoMock` requires the protocol name to end in `Protocol` (e.g. `HomeComponentModelProtocol`) so the mock class name can be derived (`HomeComponentModelMock`)"
            case .unsupportedRequirement:
                "`@AutoMock` does not yet support this requirement kind; declare the mock class manually for this protocol"
            }
        }

        public var diagnosticID: MessageID {
            MessageID(domain: "AutoMockMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity { .error }
    }
}
