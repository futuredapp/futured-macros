import SwiftSyntax

/// Maps an as-written `TypeSyntax` to a default expression for stored
/// properties and to a return-value expression for method bodies.
///
/// Detection works on the *spelling* of the type (the user-written tokens),
/// not on the resolved Swift type — the macro has no access to the type
/// checker. `[String]` and `Array<String>` resolve to the same Swift type but
/// only `[String]` is what we see at this layer; both are handled.
enum TypeDefaults {
    /// Trivially defaultable primitive type names.
    private static let numericTypes: Set<String> = [
        "Int", "Int8", "Int16", "Int32", "Int64",
        "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
        "Float", "Float32", "Float64", "Double", "CGFloat"
    ]

    /// Returns the default initializer expression for the given type, or
    /// `nil` if the type isn't trivially defaultable. Properties of
    /// non-defaultable type become required `init` parameters.
    static func defaultExpression(for type: TypeSyntax) -> String? {
        // Optional<T> — any of `T?`, `Optional<T>`, `T!`.
        if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return "nil"
        }
        if let generic = type.as(IdentifierTypeSyntax.self),
           generic.name.text == "Optional",
           generic.genericArgumentClause != nil {
            return "nil"
        }

        // Array<T> — either `[T]` or `Array<T>`.
        if type.is(ArrayTypeSyntax.self) {
            return "[]"
        }
        if let generic = type.as(IdentifierTypeSyntax.self),
           generic.name.text == "Array",
           generic.genericArgumentClause != nil {
            return "[]"
        }

        // Set<T>.
        if let generic = type.as(IdentifierTypeSyntax.self),
           generic.name.text == "Set",
           generic.genericArgumentClause != nil {
            return "[]"
        }

        // Dictionary<K, V> — either `[K: V]` or `Dictionary<K, V>`.
        if type.is(DictionaryTypeSyntax.self) {
            return "[:]"
        }
        if let generic = type.as(IdentifierTypeSyntax.self),
           generic.name.text == "Dictionary",
           generic.genericArgumentClause != nil {
            return "[:]"
        }

        // Primitive identifier types.
        if let identifier = type.as(IdentifierTypeSyntax.self),
           identifier.genericArgumentClause == nil {
            let name = identifier.name.text
            switch name {
            case "String": return "\"\""
            case "Bool": return "false"
            default:
                if numericTypes.contains(name) {
                    return "0"
                }
                return nil
            }
        }

        return nil
    }

    /// Returns the body literal (including the surrounding braces) for a
    /// method whose return clause is `returnType` (or `nil` for `Void`).
    ///
    /// - `Void` / nil return → `{}`
    /// - Primitive returns → hardcoded primitive value
    /// - Optional / Array / Dictionary returns → `{ nil }` / `{ [] }` / `{ [:] }`
    /// - Custom return → `{ fatalError(...) }` that points at the calling site
    static func functionBody(returnType: TypeSyntax?, mockClassReference: String) -> String {
        guard let returnType else {
            return "{}"
        }

        if let value = defaultExpression(for: returnType) {
            return "{ \(value) }"
        }

        // Unknown return type — caller must override the mock to use this method.
        return """
        {
            fatalError("\\(#function) not stubbed in \\(\(mockClassReference)) — override the mock to use this method")
        }
        """
    }
}
