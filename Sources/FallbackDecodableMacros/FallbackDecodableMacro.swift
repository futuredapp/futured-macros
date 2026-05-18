import SwiftSyntax
import SwiftSyntaxMacros

public enum DefaultableEnumMacro {
    struct ParsedCase {
        let name: String
        let associatedTypes: [String]
    }

    /// Extracts the flat list of cases from an enum's member block.
    static func parseCases(_ enumDecl: EnumDeclSyntax) -> [ParsedCase] {
        var result: [ParsedCase] = []
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                let name = element.name.text
                let types: [String] = element.parameterClause?.parameters.map {
                    "\($0.type)".trimmingCharacters(in: .whitespaces)
                } ?? []
                result.append(ParsedCase(name: name, associatedTypes: types))
            }
        }
        return result
    }

    /// Pulls the raw type name out of the inheritance clause, filtering out
    /// known protocol names that don't function as raw types.
    static func parseRawType(_ enumDecl: EnumDeclSyntax) -> String? {
        guard let firstInheritance = enumDecl.inheritanceClause?.inheritedTypes.first?.type else {
            return nil
        }
        let typeName = "\(firstInheritance)".trimmingCharacters(in: .whitespaces)
        let knownProtocols: Set<String> = [
            "Codable", "Decodable", "Encodable",
            "Sendable", "Equatable", "Hashable", "Identifiable",
            "CaseIterable", "RawRepresentable",
            "DefaultableDecodableEnum"
        ]
        return knownProtocols.contains(typeName) ? nil : typeName
    }

    /// Parses the macro's `fallback:` argument as a case name (e.g. `.unknown` -> `"unknown"`).
    static func parseFallbackCaseName(_ node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return nil }
        for arg in arguments where arg.label?.text == "fallback" {
            if let memberAccess = arg.expression.as(MemberAccessExprSyntax.self) {
                return memberAccess.declName.baseName.text
            }
        }
        return nil
    }
}
