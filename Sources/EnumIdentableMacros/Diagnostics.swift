//
//  Diagnostics.swift
//  FuturedMacros
//
//  Created by Mikoláš Stuchlík on 20.01.2025.
//

import SwiftDiagnostics

extension EnumIdentableMacro {
    public enum Diagnostics: String, DiagnosticMessage {

        case mustBeEnum, mustHaveCases

        public var message: String {
            switch self {
            case .mustBeEnum:
                return "`@EnumIdentableMacro` can only be applied to an `enum`"
            case .mustHaveCases:
                return "`@EnumIdentableMacro` can only be applied to an `enum` with `case` statements"
            }
        }

        public var diagnosticID: MessageID {
            MessageID(domain: "EnumIdentableMacro", id: rawValue)
        }

        public var severity: DiagnosticSeverity { .error }
    }
}
